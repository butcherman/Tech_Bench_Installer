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
# shellcheck source=lib/docker-install.sh
source "${LIB_DIR}/docker-install.sh"
# shellcheck source=lib/install-config.sh
source "${LIB_DIR}/install-config.sh"
# shellcheck source=lib/tls-setup.sh
source "${LIB_DIR}/tls-setup.sh"
# shellcheck source=lib/deploy.sh
source "${LIB_DIR}/deploy.sh"

main() {
    tb_banner
    tb_require_root
    tb_check_supported_os
    tb_check_architecture
    tb_check_required_commands
    tb_check_network
    tb_ensure_docker
    tb_prepare_installation
    tb_configure_tls
    tb_deploy_tech_bench

    tb_info "Tech Bench installation completed successfully."
}

main "$@"
