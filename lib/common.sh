#!/usr/bin/env bash
#
# Shared output and error-handling helpers.
#

TB_NAME="Tech Bench Installer"

tb_banner() {
    printf '\n'
    printf '%s\n' "============================================================"
    printf '  %s\n' "$TB_NAME"
    printf '%s\n' "  Customer installation for Tech Bench"
    printf '%s\n\n' "============================================================"
}

tb_info() {
    printf '[INFO] %s\n' "$*"
}

tb_warn() {
    printf '[WARN] %s\n' "$*" >&2
}

tb_error() {
    printf '[ERROR] %s\n' "$*" >&2
}

tb_die() {
    tb_error "$*"
    exit 1
}

tb_require_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        tb_die "Please run this installer as root, for example: sudo ./install.sh"
    fi
}
