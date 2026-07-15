#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGE_DIR="$ROOT_DIR/package"
PLUGIN_ID="com.alexey-anufriev.codexstatus"

run_package_tool() {
    if [[ -n "${HOME:-}" && "${XDG_DATA_HOME:-}" == "$HOME"/snap/* ]]; then
        env -u XDG_DATA_HOME kpackagetool6 --type Plasma/Applet "$@"
    else
        kpackagetool6 --type Plasma/Applet "$@"
    fi
}

install_package() {
    if ! command -v jq >/dev/null 2>&1; then
        printf '%s\n' "jq was not found. Install jq before using Codex Status." >&2
        return 1
    fi

    chmod +x "$PACKAGE_DIR"/contents/tools/*.sh
    if run_package_tool --show "$PLUGIN_ID" >/dev/null 2>&1; then
        run_package_tool --upgrade "$PACKAGE_DIR"
    else
        run_package_tool --install "$PACKAGE_DIR"
    fi

    printf '\n%s\n%s\n' \
        "Installed Codex Status." \
        "Add it from: Panel edit mode -> Add Widgets -> Codex Status"
}

if ! command -v kpackagetool6 >/dev/null 2>&1; then
    printf '%s\n' \
        "kpackagetool6 was not found. Install the KDE Plasma 6 package tools first." >&2
    exit 1
fi

case "${1:-}" in
    install)
        install_package
        ;;
    remove)
        run_package_tool --remove "$PLUGIN_ID"
        ;;
    *)
        printf 'Usage: %s {install|remove}\n' "${0##*/}" >&2
        exit 2
        ;;
esac
