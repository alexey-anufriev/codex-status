#!/usr/bin/env bash

set -uo pipefail

MARKER="__CODEX_STATUS_EXECUTABLE__="
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
script_path="$script_dir/$(basename "${BASH_SOURCE[0]}")"

source "$script_dir/lib/common.sh"
source "$script_dir/lib/discovery.sh"

if [[ "${1:-}" == "--from-shell" ]]; then
    codex_path="$(command -v codex 2>/dev/null || true)"
    if is_absolute_executable "$codex_path"; then
        printf '%s%s\n' "$MARKER" "$codex_path"
        exit 0
    fi
    exit 1
fi

trap cleanup_discovery EXIT INT TERM
require_jq || exit 1
if ! ensure_home; then
    json_error "HOME is not set and could not be determined"
    exit 1
fi

shell_path="$(account_shell || true)"
if [[ -z "$shell_path" ]]; then
    json_error "Unable to determine an executable login shell for this account"
    exit 1
fi

run_in_login_shell "$shell_path" "$script_path"
status=$?
if ((status != 0)); then
    if ((status == 124)); then
        json_error "Codex discovery timed out while starting $shell_path"
    else
        stderr_text="$(tail -n 5 "$discovery_stderr" 2>/dev/null || true)"
        json_error "Codex discovery failed in $shell_path${stderr_text:+: $stderr_text}"
    fi
    exit 1
fi

codex_path="$(sed -n "s/^${MARKER}//p" "$discovery_stdout" | tail -n 1)"
if ! is_absolute_executable "$codex_path"; then
    json_error "Codex CLI was not found in the interactive login shell: $shell_path"
    exit 1
fi

jq -cn --arg codexPath "$codex_path" '{
    ok: true,
    codexPath: $codexPath,
    message: "Codex CLI found. Apply the settings to save it"
}'
