.pragma library

// Strip // and /* */ comments, respecting string literals.
function strip(text) {
    let result = ""
    let inString = false
    let escape = false
    let i = 0
    while (i < text.length) {
        const c = text[i]
        if (inString) {
            result += c
            if (escape)          escape = false
            else if (c === "\\") escape = true
            else if (c === '"')  inString = false
            i++
            continue
        }
        if (c === '"') { inString = true; result += c; i++; continue }
        if (c === '/' && text[i + 1] === '/') {
            while (i < text.length && text[i] !== '\n') i++
            continue
        }
        if (c === '/' && text[i + 1] === '*') {
            i += 2
            while (i < text.length && !(text[i] === '*' && text[i + 1] === '/')) i++
            i += 2
            continue
        }
        result += c
        i++
    }
    return result
}
