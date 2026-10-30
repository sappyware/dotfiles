#!/usr/bin/env bash
# Usage: ./fix_refresh_click.sh "import QtQuick.txt"
set -euo pipefail
FILE="${1:?usage: $0 <lyrics-widget.qml>}"
python3 - "$FILE" <<'PYEOF'
import sys, shutil, re

path = sys.argv[1]
with open(path, 'rb') as f:
    raw = f.read()
crlf = b'\r\n' in raw
src = raw.decode('utf-8').replace('\r\n', '\n')
original = src

def ok(m): print(f'  [ok]   {m}')
def sk(m): print(f'  [skip] {m}')
def wn(m): print(f'  [warn] {m}')

def find_brace_close(s, brace_pos):
    depth = 0
    for i in range(brace_pos, len(s)):
        if s[i] == '{': depth += 1
        elif s[i] == '}':
            depth -= 1
            if depth == 0: return i
    return -1

def get_indent(s, pos):
    ls = s.rfind('\n', 0, pos) + 1
    return s[ls:pos]

# ---------- 1. `property bool refreshing` ----------
if re.search(r'\bproperty\s+bool\s+refreshing\b', src):
    sk('refreshing property')
else:
    anchor = None
    for pat in [r'^[ \t]*function\s+refresh\s*\(',
                r'^[ \t]*function\s+load\s*\(',
                r'^[ \t]*property\s+var\s+options\s*:']:
        m = re.search(pat, src, re.MULTILINE)
        if m:
            anchor = m; break
    if anchor:
        ls = src.rfind('\n', 0, anchor.start()) + 1
        ind = src[ls:anchor.start()]
        src = src[:ls] + f'{ind}property bool refreshing: false\n\n' + src[ls:]
        ok('inserted refreshing property')
    else:
        wn('could not insert refreshing property')

# ---------- 2. refresh() body ----------
m = re.search(r'function\s+refresh\s*\([^)]*\)\s*\{', src)
refresh_body_tpl = (
    'function refresh() {{\n'
    '{i}    if (title === "" || refreshing)\n'
    '{i}        return\n'
    '{i}    if (lrcProc.running) lrcProc.running = false\n'
    '{i}    if (metadataProc.running) metadataProc.running = false\n'
    '{i}    if (getProc.running) getProc.running = false\n'
    '{i}    if (searchProc.running) searchProc.running = false\n'
    '{i}    lines = []\n'
    '{i}    status = "Refreshing lyrics..."\n'
    '{i}    refreshing = true\n'
    '{i}    refreshDelay.restart()\n'
    '{i}}}'
)
if m:
    brace = src.find('{', m.start())
    close = find_brace_close(src, brace)
    if close < 0:
        wn('refresh() closing brace not found')
    else:
        body = src[brace+1:close]
        if 'refreshDelay.restart()' in body:
            sk('refresh() body already patched')
        else:
            ind = get_indent(src, m.start())
            new = refresh_body_tpl.format(i=ind)
            src = src[:m.start()] + new + src[close+1:]
            ok('replaced refresh() body (brace-counted)')
else:
    m = re.search(r'^[ \t]*function\s+load\s*\(', src, re.MULTILINE)
    if m:
        ls = src.rfind('\n', 0, m.start()) + 1
        ind = src[ls:m.start()]
        fn = refresh_body_tpl.format(i=ind) + '\n\n'
        src = src[:m.start()] + fn + src[m.start():]
        ok('inserted refresh() function (was missing)')
    else:
        wn('could not locate load() to insert refresh() before')

# ---------- 3. refreshDelay Timer ----------
if re.search(r'\bid\s*:\s*refreshDelay\b', src):
    sk('refreshDelay Timer')
else:
    m = re.search(r'^([ \t]*)Timer\s*\{\s*\n[ \t]*id\s*:\s*debounce',
                  src, re.MULTILINE)
    if m:
        ind = m.group(1)
        timer = (
            f'{ind}// Hold "Refreshing..." long enough to be visible.\n'
            f'{ind}Timer {{\n'
            f'{ind}    id: refreshDelay\n'
            f'{ind}    interval: 600\n'
            f'{ind}    repeat: false\n'
            f'{ind}    onTriggered: {{\n'
            f'{ind}        root.load()\n'
            f'{ind}        root.refreshing = false\n'
            f'{ind}    }}\n'
            f'{ind}}}\n\n'
        )
        src = src[:m.start()] + timer + src[m.start():]
        ok('inserted refreshDelay Timer')
    else:
        wn('debounce Timer not found')

# ---------- 4. lyric row MouseArea ----------
if 'onDoubleClicked: root.refresh()' in src:
    sk('lyric row MouseArea already patched')
else:
    ref = src.find('lyricRow.modelData.t')
    if ref < 0:
        wn('lyricRow.modelData.t not found — skipping row MouseArea')
    else:
        candidates = list(re.finditer(r'MouseArea\s*\{', src[:ref]))
        if not candidates:
            wn('no MouseArea before lyricRow reference')
        else:
            ma = candidates[-1]
            brace = src.find('{', ma.start())
            close = find_brace_close(src, brace)
            if close < 0:
                wn('lyric row MouseArea closing brace not found')
            else:
                ind = get_indent(src, ma.start())
                new_ma = (
                    f'MouseArea {{\n'
                    f'{ind}    anchors.fill: parent\n'
                    f'{ind}    onClicked: {{\n'
                    f'{ind}        if (root.player && root.player.canSeek) {{\n'
                    f'{ind}            root.player.position = Math.max(\n'
                    f'{ind}                0,\n'
                    f'{ind}                lyricRow.modelData.t - root.offset\n'
                    f'{ind}            )\n'
                    f'{ind}        }} else {{\n'
                    f'{ind}            root.refresh()\n'
                    f'{ind}        }}\n'
                    f'{ind}    }}\n'
                    f'{ind}    onDoubleClicked: root.refresh()\n'
                    f'{ind}}}'
                )
                src = src[:ma.start()] + new_ma + src[close+1:]
                ok('replaced lyric row MouseArea')

# ---------- summary ----------
print()
print('Summary:')
print('  refreshing property :', 'yes' if 'property bool refreshing' in src else 'NO')
print('  refresh() body      :', 'yes' if 'refreshDelay.restart()' in src else 'NO')
print('  refreshDelay timer  :', 'yes' if 'id: refreshDelay' in src else 'NO')
print('  double-click refresh:', 'yes' if 'onDoubleClicked: root.refresh()' in src else 'NO')

if src == original:
    print('\nNothing changed.')
    sys.exit(0)

shutil.copy2(path, path + '.bak')
out = src.replace('\n', '\r\n') if crlf else src
with open(path, 'w', encoding='utf-8', newline='') as f:
    f.write(out)
print(f'\nWrote {path} (backup: {path}.bak)')
PYEOF