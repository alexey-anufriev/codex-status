#!/usr/bin/env bash

json_error() {
    jq -cn --arg message "$1" '{ok: false, error: $message}'
}

require_jq() {
    if command -v jq >/dev/null 2>&1; then
        return 0
    fi

    printf '%s\n' '{"ok":false,"error":"Required command not found: jq"}'
    return 1
}

is_absolute_executable() {
    [[ "$1" == /* && -f "$1" && -x "$1" ]]
}

ensure_home() {
    if [[ -n "${HOME:-}" ]]; then
        return 0
    fi

    HOME="$(getent passwd "$(id -u)" 2>/dev/null | cut -d: -f6)"
    export HOME
    [[ -n "$HOME" ]]
}
