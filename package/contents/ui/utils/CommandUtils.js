.pragma library

function localPath(url) {
    const value = String(url)
    if (value.startsWith("file://")) {
        return decodeURIComponent(value.substring(7))
    }
    return decodeURIComponent(value)
}

function shellQuote(value) {
    return "'" + String(value).replace(/'/g, "'\\''") + "'"
}

function command(executable, args, requestId) {
    const parts = [shellQuote(executable)]
    for (const argument of args) {
        parts.push(shellQuote(argument))
    }
    parts.push(String(Number(requestId)))
    return parts.join(" ")
}
