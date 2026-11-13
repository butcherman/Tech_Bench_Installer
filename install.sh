#!/usr/bin/env bash
#
# Tech Bench Installer
# Supported platforms: Debian and Ubuntu
#

set -Eeuo pipefail

INSTALLER_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${INSTALLER_DIR}/lib"

# shellcheck source=lib/common.sh
source "${LIB_DIR}/common.sh"
# shellcheck source=lib/system-checks.sh
source "${LIB_DIR}/system-checks.sh"

main() {
    tb_banner
    tb_require_root
    tb_check_supported_os
    tb_check_architecture
    tb_check_required_commands
    tb_check_network

    tb_info "Initial system checks passed."
    tb_info "Docker installation and application deployment will be added in the next installer stages."
}

main "$@"
