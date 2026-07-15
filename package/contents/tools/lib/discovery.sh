#!/usr/bin/env bash

DISCOVERY_TIMEOUT_SECONDS=15
discovery_pid=""
discovery_stdout=""
discovery_stderr=""

cleanup_discovery() {
    if [[ -n "$discovery_pid" ]] && kill -0 "$discovery_pid" 2>/dev/null; then
        kill -TERM "$discovery_pid" 2>/dev/null || true
        wait "$discovery_pid" 2>/dev/null || true
    fi
    [[ -n "$discovery_stdout" ]] && rm -f "$discovery_stdout"
    [[ -n "$discovery_stderr" ]] && rm -f "$discovery_stderr"
}

account_shell() {
    local value

    value="$(getent passwd "$(id -u)" 2>/dev/null | cut -d: -f7)"
    [[ -n "$value" ]] || value="${SHELL:-/bin/sh}"
    [[ -x "$value" ]] || return 1
    printf '%s\n' "$value"
}

wait_for_discovery() {
    local deadline=$((SECONDS + DISCOVERY_TIMEOUT_SECONDS))
    local state

    while true; do
        state="$(ps -o stat= -p "$discovery_pid" 2>/dev/null || true)"
        [[ -n "$state" && "$state" != Z* ]] || break

        if ((SECONDS >= deadline)); then
            kill -TERM "$discovery_pid" 2>/dev/null || true
            wait "$discovery_pid" 2>/dev/null || true
            discovery_pid=""
            return 124
        fi
        sleep 0.1
    done

    wait "$discovery_pid"
    local status=$?
    discovery_pid=""
    return "$status"
}

run_in_login_shell() {
    local shell_path="$1"
    local helper_path="$2"

    discovery_stdout="$(mktemp "${TMPDIR:-/tmp}/codex-discovery.stdout.XXXXXX")" || return 1
    discovery_stderr="$(mktemp "${TMPDIR:-/tmp}/codex-discovery.stderr.XXXXXX")" || return 1

    # $1 must be expanded by the spawned login shell, not by this process.
    # shellcheck disable=SC2016
    "$shell_path" -l -i -c '"$1" --from-shell' shell "$helper_path" \
        >"$discovery_stdout" 2>"$discovery_stderr" &
    discovery_pid=$!
    wait_for_discovery
}
