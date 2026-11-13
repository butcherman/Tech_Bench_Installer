#!/usr/bin/env bash
#
# Configure TLS material for the Tech Bench NGINX container.
#

TB_KEYSTORE_VOLUME="tech-bench_keystoreData"
TB_COMPOSE_PROJECT_NAME="tech-bench"

tb_copy_certificate_to_volume() {
    local source_dir="$1"
    local cert_file="$2"
    local key_file="$3"

    docker volume create "$TB_KEYSTORE_VOLUME" >/dev/null
    docker run --rm --user 0:0 \
        -v "$TB_KEYSTORE_VOLUME:/target" \
        -v "$source_dir:/source:ro" \
        alpine:3.22 sh -ec "
            mkdir -p /target/private
            cp \"/source/$cert_file\" /target/server.crt
            cp \"/source/$key_file\" /target/private/server.key
            chmod 644 /target/server.crt
            chmod 640 /target/private/server.key
            chown 0:101 /target/private/server.key
        "
}

tb_write_letsencrypt_deploy_hook() {
    local install_dir="$1"
    local domain="$2"
    local hook="/etc/letsencrypt/renewal-hooks/deploy/tech-bench-${domain}.sh"

    install -d -m 0755 /etc/letsencrypt/renewal-hooks/deploy

    cat > "$hook" <<EOF
#!/usr/bin/env bash
set -Eeuo pipefail
docker run --rm --user 0:0 \
    -v "${TB_KEYSTORE_VOLUME}:/target" \
    -v "/etc/letsencrypt:/letsencrypt:ro" \
    alpine:3.22 sh -ec '
        mkdir -p /target/private
        cp "/letsencrypt/live/${domain}/fullchain.pem" /target/server.crt
        cp "/letsencrypt/live/${domain}/privkey.pem" /target/private/server.key
        chmod 644 /target/server.crt
        chmod 640 /target/private/server.key
        chown 0:101 /target/private/server.key
    '
docker compose --project-name "${TB_COMPOSE_PROJECT_NAME}" --project-directory "${install_dir}" \
    -f "${install_dir}/docker-compose.yml" restart nginx
EOF
    chmod 0750 "$hook"
}

tb_configure_letsencrypt() {
    local domain="$1"
    local install_dir="$2"
    local email hook cert_dir compose_cmd

    [[ "$domain" != *.* ]] && tb_die "Let's Encrypt requires a fully qualified domain name."
    [[ "$domain" =~ ^[A-Za-z0-9.-]+$ ]] || tb_die "The domain name contains unsupported characters."
    [[ ! "$domain" =~ ^[0-9.]+$ ]] || tb_die "Let's Encrypt certificates require a DNS hostname, not an IP address."

    email="$(tb_prompt_value "Email address for Let's Encrypt expiry notices" "")"
    [[ "$email" =~ ^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$ ]] || tb_die "A valid email address is required for Let's Encrypt."

    if ! command -v certbot >/dev/null 2>&1; then
        tb_info "Installing Certbot from the Debian/Ubuntu package repository."
        apt-get update
        apt-get install -y certbot
    fi

    hook="/etc/letsencrypt/renewal-hooks/deploy/tech-bench-${domain}.sh"
    tb_write_letsencrypt_deploy_hook "$install_dir" "$domain"

    printf -v compose_cmd 'docker compose --project-name %q --project-directory %q -f %q' "$TB_COMPOSE_PROJECT_NAME" "$install_dir" "$install_dir/docker-compose.yml"

    tb_info "Requesting a Let's Encrypt certificate for $domain."
    tb_warn "Port 80 must be reachable from the public internet, and DNS must point to this server."
    certbot certonly --standalone --preferred-challenges http \
        --non-interactive --agree-tos --email "$email" -d "$domain" \
        --pre-hook "$compose_cmd stop nginx || true" \
        --post-hook "$compose_cmd start nginx || true" \
        --deploy-hook "$hook"

    cert_dir="/etc/letsencrypt/live/$domain"
    [[ -s "$cert_dir/fullchain.pem" && -s "$cert_dir/privkey.pem" ]] || tb_die "Certbot did not create the expected certificate files."
    tb_copy_certificate_to_volume "/etc/letsencrypt" "live/$domain/fullchain.pem" "live/$domain/privkey.pem"
    if command -v systemctl >/dev/null 2>&1 && systemctl list-unit-files certbot.timer >/dev/null 2>&1; then
        systemctl enable --now certbot.timer
    else
        tb_warn "Certbot timer was not found; automatic renewal may need to be enabled manually."
    fi

    tb_info "Let's Encrypt certificate installed. Certbot renewal hooks are configured."
}

tb_configure_self_signed() {
    local domain="$1"
    local temp_dir san

    command -v openssl >/dev/null 2>&1 || {
        apt-get update
        apt-get install -y openssl
    }

    temp_dir="$(mktemp -d)"
    case "$domain" in
        *[!0-9.]*)
            san="DNS:$domain"
            ;;
        *)
            san="IP:$domain"
            ;;
    esac

    openssl req -x509 -nodes -newkey rsa:2048 -sha256 -days 3650 \
        -keyout "$temp_dir/server.key" \
        -out "$temp_dir/server.crt" \
        -subj "/CN=$domain" \
        -addext "subjectAltName=$san"

    tb_copy_certificate_to_volume "$temp_dir" "server.crt" "server.key"
    rm -rf "$temp_dir"
    tb_info "Self-signed certificate installed. Browsers and clients will need to trust it manually."
}

tb_configure_tls() {
    local env_file domain install_dir choice replace_cert

    install_dir="$TB_INSTALL_DIR"
    env_file="$install_dir/.env"
    domain="$(tb_env_value BASE_URL "$env_file")"
    TB_COMPOSE_PROJECT_NAME="$(tb_env_value COMPOSE_PROJECT_NAME "$env_file")"
    TB_COMPOSE_PROJECT_NAME="${TB_COMPOSE_PROJECT_NAME:-tech-bench}"
    [[ "$TB_COMPOSE_PROJECT_NAME" =~ ^[a-z0-9_-]+$ ]] || tb_die "Invalid COMPOSE_PROJECT_NAME in .env."
    TB_KEYSTORE_VOLUME="${TB_COMPOSE_PROJECT_NAME}_keystoreData"

    [[ -n "$domain" ]] || tb_die "BASE_URL must be set before configuring HTTPS."

    if docker volume inspect "$TB_KEYSTORE_VOLUME" >/dev/null 2>&1; then
        if docker run --rm -v "$TB_KEYSTORE_VOLUME:/target:ro" alpine:3.22 sh -c 'test -s /target/server.crt && test -s /target/private/server.key' >/dev/null 2>&1; then
            read -r -p "An existing TLS certificate was found. Replace it? [y/N]: " replace_cert
            if [[ ! "$replace_cert" =~ ^[Yy]$ ]]; then
                tb_info "Preserving the existing TLS certificate."
                return 0
            fi
        fi
    fi

    echo
    tb_info "Choose the HTTPS certificate type:"
    printf '  1) Let'\''s Encrypt (publicly trusted; requires a public DNS name and inbound port 80)\n'
    printf '  2) Self-signed (works without public DNS; clients will show a trust warning)\n'
    read -r -p "Certificate choice [1/2]: " choice

    case "$choice" in
        1) tb_configure_letsencrypt "$domain" "$install_dir" ;;
        2) tb_configure_self_signed "$domain" ;;
        *) tb_die "Choose 1 for Let's Encrypt or 2 for self-signed." ;;
    esac
}
