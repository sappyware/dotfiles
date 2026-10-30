#!/usr/bin/env python3
"""qmlfmt - strip comments from and/or re-indent QML / JS files.

  qmlfmt.py File.qml                 format, print to stdout
  qmlfmt.py -i src/                  format every .qml/.js under src/, in place
  qmlfmt.py -s -i File.qml           strip comments + format, in place
  qmlfmt.py -s --no-format File.qml  strip comments only
  qmlfmt.py --check src/             exit 1 if any file would change (CI)
  cat File.qml | qmlfmt.py -s -      stdin -> stdout

Safe around strings, template literals (`...`) and regex literals, so "http://x",
`# toml text` in a template, or /"|"/ never get mangled.
"""
import argparse
import bisect
import os
import re
import sys

OPEN, CLOSE = "([{", ")]}"
REGEX_PRE = set("(,=:[!&|?{};+-*%<>~^")
REGEX_KW = {"return", "typeof", "in", "of", "case", "delete", "void", "throw", "new", "else", "do", "yield", "await"}


# ---------------------------------------------------------------- lexer
def skip_string(s, i):
    q = s[i]
    i += 1
    while i < len(s):
        c = s[i]
        if c == "\\":
            i += 2
        elif c == q:
            return i + 1
        elif c == "\n":
            return i
        else:
            i += 1
    return len(s)


def skip_expr(s, i):  # inside ${ ... }, returns index after the matching }
    depth = 1
    while i < len(s):
        c = s[i]
        if c in "\"'":
            i = skip_string(s, i)
        elif c == "`":
            i = skip_template(s, i)
        elif c == "/" and s[i + 1:i + 2] == "/":
            j = s.find("\n", i)
            i = len(s) if j < 0 else j
        elif c == "/" and s[i + 1:i + 2] == "*":
            j = s.find("*/", i + 2)
            i = len(s) if j < 0 else j + 2
        else:
            if c == "{":
                depth += 1
            elif c == "}":
                depth -= 1
                if depth == 0:
                    return i + 1
            i += 1
    return len(s)


def skip_template(s, i):
    i += 1
    while i < len(s):
        c = s[i]
        if c == "\\":
            i += 2
        elif c == "`":
            return i + 1
        elif c == "$" and s[i + 1:i + 2] == "{":
            i = skip_expr(s, i + 2)
        else:
            i += 1
    return len(s)


def skip_regex(s, i):
    i += 1
    in_class = False
    while i < len(s):
        c = s[i]
        if c == "\\":
            i += 2
            continue
        if c == "\n":
            return i
        if c == "[":
            in_class = True
        elif c == "]":
            in_class = False
        elif c == "/" and not in_class:
            i += 1
            while i < len(s) and (s[i].isalpha()):
                i += 1
            return i
        i += 1
    return len(s)


def tokenize(s):
    """-> [(kind, start, end)]  kind: code | str | rx | lc (// comment) | bc (/* comment */)"""
    toks, i, n, cs = [], 0, len(s), 0
    last, word, wend = "", "", False

    def flush(a, b):
        if b > a:
            toks.append(("code", a, b))

    while i < n:
        c = s[i]
        nxt = s[i + 1:i + 2]
        if c == "/" and nxt == "/":
            flush(cs, i)
            j = s.find("\n", i)
            j = n if j < 0 else j
            toks.append(("lc", i, j))
            i = cs = j
        elif c == "/" and nxt == "*":
            flush(cs, i)
            j = s.find("*/", i + 2)
            j = n if j < 0 else j + 2
            toks.append(("bc", i, j))
            i = cs = j
        elif c in "\"'" or c == "`":
            flush(cs, i)
            j = skip_template(s, i) if c == "`" else skip_string(s, i)
            toks.append(("str", i, j))
            i = cs = j
            last, word, wend = "a", "x", False
        elif c == "/" and (last == "" or last in REGEX_PRE or (word in REGEX_KW and (last.isalnum() or last in "_$"))):
            flush(cs, i)
            j = skip_regex(s, i)
            toks.append(("rx", i, j))
            i = cs = j
            last, word, wend = "a", "x", False
        else:
            if c.isalnum() or c in "_$":
                if wend:
                    word, wend = "", False
                word += c
                last = c
            elif c.isspace():
                if word:
                    wend = True
            else:
                word, wend = "", False
                last = c
            i += 1
    flush(cs, n)
    return toks


# ---------------------------------------------------------------- strip comments
def strip_comments(s, keep_re=None, keep_header=False):
    out, pending, header = [], False, True
    for kind, a, b in tokenize(s):
        text = s[a:b]
        if kind in ("lc", "bc"):
            if (keep_header and header) or (keep_re and keep_re.search(text)):
                out.append(text)
            else:
                out.append("\x00")
                pending = True
            continue
        if kind == "code":
            if text.strip():
                header = False
            if pending:
                t2 = text.lstrip(" \t")
                prev = "".join(out).replace("\x00", "")[-1:]
                if t2 != text and not (t2.startswith("\n") or t2 == "") and prev and prev not in " \t\n":
                    t2 = " " + t2
                elif t2 == text and prev.isalnum() and t2[:1].isalnum():
                    t2 = " " + t2
                text = t2
            pending = False
        else:
            header = False
            pending = False
        out.append(text)
    lines = []
    for ln in "".join(out).split("\n"):
        if "\x00" in ln:
            ln = ln.replace("\x00", "")
            if not ln.strip():
                continue
        lines.append(ln.rstrip() if ln.strip() else ln)
    return "\n".join(lines)


# ---------------------------------------------------------------- formatter
CTRL = re.compile(r"^(?:\}\s*)?(?:else\s+)?(?:if|for|while)\s*\(.*\)\s*$|^(?:\}\s*)?else\s*$")
CONT = re.compile(r"^(?:\?(?!\.)|:|&&|\|\||\.(?![.\d]))")


def format_code(s, indent=2):
    toks = tokenize(s)
    starts = [0] + [m.end() for m in re.finditer("\n", s)]
    nl = len(starts)
    verb = [False] * nl
    events = [[] for _ in range(nl)]
    for kind, a, b in toks:
        if kind == "code":
            for idx in range(a, b):
                ch = s[idx]
                if ch in OPEN or ch in CLOSE:
                    events[bisect.bisect_right(starts, idx) - 1].append((idx, ch))
        elif "\n" in s[a:b]:
            lo = bisect.bisect_right(starts, a)
            hi = bisect.bisect_left(starts, b)
            for L in range(lo, hi):
                verb[L] = True

    # indentation = number of distinct lines that still have an unclosed bracket,
    # so `foo(function () {` indents its body one level, not two
    rows, stack, pend = [], [], 0

    def apply(ev, L):
        for _, ch in ev:
            if ch in OPEN:
                stack.append(L)
            elif stack:
                stack.pop()

    for L in range(nl):
        end = starts[L + 1] - 1 if L + 1 < nl else len(s)
        raw = s[starts[L]:end]
        content = raw.strip()
        ev = events[L]
        if verb[L]:
            rows.append(("verb", raw, 0))
            apply(ev, L)
            continue
        if not content:
            rows.append(("blank", "", 0))
            continue
        f = starts[L] + (len(raw) - len(raw.lstrip()))
        lead, pos = 0, f
        for idx, ch in ev:
            if ch in CLOSE and idx == pos:
                lead += 1
                pos = idx + 1
                while pos < len(s) and s[pos] in " \t":
                    pos += 1
            else:
                break
        extra = pend
        if CONT.match(content):
            extra += 1
        if content.startswith("{") and pend:
            extra -= pend
        lvl = len(set(stack[:len(stack) - lead] if lead else stack)) + extra
        before = len(stack)
        apply(ev, L)
        rows.append(("line", " " * (indent * lvl) + content, lead))
        pend = pend + 1 if (CTRL.match(content) and len(stack) == before) else 0

    out = []
    for kind, text, lead in rows:
        if kind == "blank":
            if not out or out[-1][0] == "blank":
                continue
            if out[-1][0] == "line" and out[-1][1].rstrip()[-1:] in "{([":
                continue
        elif kind == "line" and lead and out and out[-1][0] == "blank":
            out.pop()
        out.append((kind, text))
    while out and out[-1][0] == "blank":
        out.pop()
    return "\n".join(t for _, t in out) + "\n"


# ---------------------------------------------------------------- cli
def process(src, args, keep_re):
    if args.strip:
        src = strip_comments(src, keep_re, args.keep_header)
    if not args.no_format:
        src = format_code(src, args.indent)
    elif not src.endswith("\n"):
        src += "\n"
    return src


def collect(paths):
    for p in paths:
        if os.path.isdir(p):
            for root, dirs, files in os.walk(p):
                dirs[:] = [d for d in dirs if not d.startswith(".")]
                for f in sorted(files):
                    if f.endswith((".qml", ".js")):
                        yield os.path.join(root, f)
        else:
            yield p


def main():
    ap = argparse.ArgumentParser(description="Strip comments from and/or format QML/JS files.")
    ap.add_argument("paths", nargs="+", help="files or directories ('-' = stdin)")
    ap.add_argument("-s", "--strip", action="store_true", help="remove comments")
    ap.add_argument("--no-format", action="store_true", help="don't re-indent")
    ap.add_argument("-i", "--in-place", action="store_true", help="write changes back to the files")
    ap.add_argument("--check", action="store_true", help="exit 1 if any file would change")
    ap.add_argument("--indent", type=int, default=2, help="spaces per level (default 2)")
    ap.add_argument("--keep", metavar="REGEX", help="keep comments matching REGEX (e.g. 'TODO|qmllint')")
    ap.add_argument("--keep-header", action="store_true", help="keep the comment block at the top of the file")
    args = ap.parse_args()
    keep_re = re.compile(args.keep) if args.keep else None

    if args.paths == ["-"]:
        sys.stdout.write(process(sys.stdin.read(), args, keep_re))
        return 0

    changed = 0
    files = list(collect(args.paths))
    for p in files:
        with open(p, encoding="utf-8") as fh:
            src = fh.read()
        new = process(src, args, keep_re)
        if new != src:
            changed += 1
        if args.check:
            if new != src:
                print("would change:", p, file=sys.stderr)
        elif args.in_place:
            if new != src:
                with open(p, "w", encoding="utf-8") as fh:
                    fh.write(new)
                print("updated:", p, file=sys.stderr)
        else:
            if len(files) > 1:
                print("// ==== " + p, file=sys.stderr)
            sys.stdout.write(new)
    return 1 if (args.check and changed) else 0


if __name__ == "__main__":
    sys.exit(main())
