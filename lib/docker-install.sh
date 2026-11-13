#!/usr/bin/env bash
#
# Docker Engine and Compose installation for Debian and Ubuntu.
#

tb_docker_is_ready() {
    command -v docker >/dev/null 2>&1 || return 1
    docker compose version >/dev/null 2>&1 || return 1
    docker info >/dev/null 2>&1 || return 1
}

tb_install_docker() {
    local os_id os_codename arch repo_url keyring source_file simulation

    . /etc/os-release
    os_id="${ID:-}"
    os_codename="${VERSION_CODENAME:-${UBUNTU_CODENAME:-}}"
    arch="$(dpkg --print-architecture)"

    if [[ "$os_id" != "debian" && "$os_id" != "ubuntu" ]]; then
        tb_die "Automatic Docker repository setup supports Debian and Ubuntu only. This system reports ID='$os_id'."
    fi

    if [[ -z "$os_codename" ]]; then
        tb_die "Could not determine the OS release codename from /etc/os-release."
    fi

    if [[ "$arch" != "amd64" && "$arch" != "arm64" ]]; then
        tb_die "Docker installation is not configured for architecture '$arch'."
    fi

    tb_info "Docker Engine and the Compose plugin are not both ready."
    tb_info "The installer will configure Docker's official repository for $os_id $os_codename."

    if [[ -x /usr/bin/docker || -x /usr/local/bin/docker ]] || dpkg-query -W -f='${Status}' docker.io 2>/dev/null | grep -q "install ok installed"; then
        tb_warn "An existing Docker installation was detected, but it is incomplete or not responding."
        read -r -p "Continue with Docker's official packages? Existing conflicting packages may be replaced [y/N]: " answer
        [[ "$answer" =~ ^[Yy]$ ]] || tb_die "Docker setup cancelled. No Docker packages were changed."
    else
        read -r -p "Install Docker Engine and the Docker Compose plugin now? [Y/n]: " answer
        [[ -z "$answer" || "$answer" =~ ^[Yy]$ ]] || tb_die "Docker installation declined."
    fi

    apt-get update
    apt-get install -y ca-certificates curl

    install -m 0755 -d /etc/apt/keyrings
    keyring="/etc/apt/keyrings/docker.asc"
    curl -fsSL "https://download.docker.com/linux/$os_id/gpg" -o "$keyring"
    chmod a+r "$keyring"

    source_file="/etc/apt/sources.list.d/docker.sources"
    cat > "$source_file" <<EOF
Types: deb
URIs: https://download.docker.com/linux/$os_id
Suites: $os_codename
Components: stable
Architectures: $arch
Signed-By: $keyring
EOF

    apt-get update

    simulation="$(apt-get -s install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin)"
    if grep -Eq '^Remv ' <<<"$simulation"; then
        tb_warn "APT indicates that installing Docker's official packages will remove existing packages:"
        grep '^Remv ' <<<"$simulation" || true
        read -r -p "Proceed with these package changes? [y/N]: " answer
        [[ "$answer" =~ ^[Yy]$ ]] || tb_die "Docker package installation cancelled."
    fi

    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    if command -v systemctl >/dev/null 2>&1; then
        systemctl enable --now docker
    else
        tb_warn "systemctl is unavailable; start the Docker daemon using this system's service manager."
    fi

    if ! docker compose version; then
        tb_die "Docker was installed, but the Docker Compose plugin could not be run."
    fi

    if ! docker info >/dev/null 2>&1; then
        tb_die "Docker packages are installed, but the Docker daemon is not responding."
    fi

    tb_info "Docker Engine and Docker Compose are ready."
}

tb_ensure_docker() {
    if tb_docker_is_ready; then
        tb_info "Existing Docker Engine and Docker Compose installation detected; leaving it unchanged."
        return 0
    fi

    # An existing working installation may only need its service started.
    if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
        if command -v systemctl >/dev/null 2>&1; then
            systemctl start docker || true
        fi
        if tb_docker_is_ready; then
            tb_info "Existing Docker installation is ready."
            return 0
        fi
    fi

    tb_install_docker
}
