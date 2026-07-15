#!/usr/bin/env bash

RPC_TIMEOUT_SECONDS=12
server_pid=""
server_in=""
server_out=""
server_stderr=""

stop_app_server() {
    if [[ -n "$server_in" ]]; then
        eval "exec ${server_in}>&-" 2>/dev/null || true
    fi
    if [[ -n "$server_out" ]]; then
        eval "exec ${server_out}<&-" 2>/dev/null || true
    fi

    if [[ -n "$server_pid" ]] && kill -0 "$server_pid" 2>/dev/null; then
        kill -TERM "$server_pid" 2>/dev/null || true
        for _ in {1..20}; do
            kill -0 "$server_pid" 2>/dev/null || break
            sleep 0.05
        done
        kill -KILL "$server_pid" 2>/dev/null || true
    fi

    if [[ -n "$server_pid" ]]; then
        wait "$server_pid" 2>/dev/null || true
    fi
    [[ -n "$server_stderr" ]] && rm -f "$server_stderr"
}

send_rpc() {
    printf '%s\n' "$1" >&"$server_in"
}

read_rpc() {
    local expected_id="$1"
    local line
    local deadline=$((SECONDS + RPC_TIMEOUT_SECONDS))

    while ((SECONDS < deadline)); do
        if IFS= read -r -t 1 -u "$server_out" line; then
            if jq -e --argjson id "$expected_id" '.id == $id' \
                >/dev/null 2>&1 <<<"$line"; then
                printf '%s\n' "$line"
                return 0
            fi
        elif ! kill -0 "$server_pid" 2>/dev/null; then
            return 2
        fi
    done
    return 1
}

receive_rpc() {
    local expected_id="$1"
    local action="$2"
    local response
    local status
    local stderr_text

    response="$(read_rpc "$expected_id")"
    status=$?
    if ((status == 0)); then
        printf '%s\n' "$response"
        return 0
    fi

    stderr_text="$(cat "$server_stderr" 2>/dev/null || true)"
    if ((status == 2)); then
        json_error "codex app-server exited while $action${stderr_text:+: $stderr_text}"
    else
        json_error "Timed out while $action${stderr_text:+: $stderr_text}"
    fi
    return 1
}

rpc_error_message() {
    jq -r '.error.message // (.error | tostring)' <<<"$1"
}
