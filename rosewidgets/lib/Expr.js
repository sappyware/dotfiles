.pragma library

// Evaluate `{expr}` placeholders inside a string against a context object.
function evalValue(str, context) {
    if (typeof str !== "string") return str
    if (str.indexOf("{") === -1) return str

    return str.replace(/\{([^{}]+)\}/g, function (_, expr) {
        try {
            const ctx = context || {}
            const keys = Object.keys(ctx)
            const vals = keys.map(function (k) { return ctx[k] })
            const argNames = keys.join(",")
            const body = "return (" + expr + ");"
            // new Function(paramNames, body) avoids spread-in-call syntax
            // which QML's V4 engine doesn't consistently support.
            const fn = new Function(argNames, body)
            const result = fn.apply(null, vals)
            return (result === undefined || result === null) ? "" : String(result)
        } catch (e) {
            console.warn("[roseforge] expr error:", expr, e.message)
            return "?"
        }
    })
}

// Resolve theme tokens: "@muted" -> Theme.muted
function evalColor(value, theme) {
    if (typeof value !== "string") return value
    if (value.charAt(0) === "@") {
        const key = value.slice(1)
        const resolved = theme.token(key)
        return (resolved !== null && resolved !== undefined) ? resolved : value
    }
    return value
}
