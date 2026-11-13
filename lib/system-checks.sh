#!/usr/bin/env bash
#
# Validate the host before making system changes.
#

tb_check_supported_os() {
    local os_id=""
    local os_like=""

    if [[ ! -r /etc/os-release ]]; then
        tb_die "Cannot identify this Linux distribution: /etc/os-release is missing."
    fi

    # shellcheck disable=SC1091
    source /etc/os-release
    os_id="${ID:-}"
    os_like="${ID_LIKE:-}"

    case "$os_id" in
        debian|ubuntu)
            ;;
        *)
            if [[ " $os_like " == *" debian "* || " $os_like " == *" ubuntu "* ]]; then
                tb_warn "Detected Debian/Ubuntu derivative: ${PRETTY_NAME:-$os_id}."
                tb_warn "Only Debian and Ubuntu are officially supported at this stage."
                read -r -p "Continue anyway? [y/N] " answer
                [[ "$answer" =~ ^[Yy]$ ]] || tb_die "Installation cancelled."
            else
                tb_die "Unsupported operating system: ${PRETTY_NAME:-$os_id}. Debian and Ubuntu are supported."
            fi
            ;;
    esac

    tb_info "Operating system: ${PRETTY_NAME:-$os_id}"
}

tb_check_architecture() {
    local architecture
    architecture="$(dpkg --print-architecture 2>/dev/null || true)"

    case "$architecture" in
        amd64|arm64)
            tb_info "Architecture: $architecture"
            ;;
        *)
            tb_die "Unsupported architecture: ${architecture:-unknown}. Supported architectures are amd64 and arm64."
            ;;
    esac
}

tb_check_required_commands() {
    local missing=()
    local command_name

    for command_name in apt-get dpkg getent; do
        command -v "$command_name" >/dev/null 2>&1 || missing+=("$command_name")
    done

    if (( ${#missing[@]} > 0 )); then
        tb_die "Required system commands are missing: ${missing[*]}"
    fi

    tb_info "Required system commands are available."
}

tb_check_network() {
    if ! getent hosts download.docker.com >/dev/null 2>&1; then
        tb_die "DNS lookup failed for download.docker.com. Check the server's DNS and internet connectivity."
    fi

    tb_info "Network/DNS check passed."
}
