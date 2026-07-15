#!/usr/bin/env bash

set -uo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
normalizer="$script_dir/normalize-rate-limits.jq"
metadata="$script_dir/../../metadata.json"

source "$script_dir/lib/common.sh"
source "$script_dir/lib/app-server.sh"

trap stop_app_server EXIT INT TERM

require_jq || exit 1
if ! ensure_home; then
    json_error "HOME is not set and could not be determined"
    exit 1
fi

if [[ ! -f "$normalizer" ]]; then
    json_error "Rate-limit normalizer was not found: $normalizer"
    exit 1
fi

codex_executable="${1:-}"
if ! is_absolute_executable "$codex_executable"; then
    json_error "Configured Codex CLI path is not an absolute executable: $codex_executable"
    exit 1
fi

codex_directory="$(dirname "$codex_executable")"
export PATH="$codex_directory:${PATH:-/usr/local/bin:/usr/bin:/bin}"
server_stderr="$(mktemp "${TMPDIR:-/tmp}/codex-status.XXXXXX")" || {
    json_error "Unable to create a temporary app-server error file"
    exit 1
}
chmod 600 "$server_stderr"

client_version="$(jq -r '.KPlugin.Version' "$metadata")"

coproc CODEX_SERVER {
    exec "$codex_executable" app-server 2>"$server_stderr"
}
server_pid="$CODEX_SERVER_PID"
server_out="${CODEX_SERVER[0]}"
server_in="${CODEX_SERVER[1]}"

initialize_request="$(jq -cn --arg client_version "$client_version" '{
    method: "initialize",
    id: 1,
    params: {
        clientInfo: {
            name: "codex_status_plasmoid",
            title: "Codex Status",
            version: $client_version
        }
    }
}')"

send_rpc "$initialize_request"
initialize_response="$(receive_rpc 1 "initializing")" || {
    printf '%s\n' "$initialize_response"
    exit 1
}
if jq -e '.error != null' >/dev/null 2>&1 <<<"$initialize_response"; then
    json_error "Codex initialization failed: $(rpc_error_message "$initialize_response")"
    exit 1
fi

send_rpc '{"method":"initialized","params":{}}'
send_rpc '{"method":"account/rateLimits/read","id":2}'
limits_response="$(receive_rpc 2 "reading Codex limits")" || {
    printf '%s\n' "$limits_response"
    exit 1
}

if jq -e '.error != null' >/dev/null 2>&1 <<<"$limits_response"; then
    error_code="$(jq -r '.error.code // empty' <<<"$limits_response")"
    if [[ "$error_code" == "-32601" ]]; then
        json_error \
            "This Codex CLI version does not support account/rateLimits/read; update Codex CLI"
    else
        json_error "Codex rate-limit request failed: $(rpc_error_message "$limits_response")"
    fi
    exit 1
fi

jq -c -f "$normalizer" <<<"$limits_response"
