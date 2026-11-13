#!/usr/bin/env bash
#
# Prepare the Tech Bench installation directory and initial environment.
#

tb_random_secret() {
    od -An -N32 -tx1 /dev/urandom | tr -d ' \n'
}

tb_env_value() {
    local key="$1"
    local file="$2"
    local line
    line="$(grep -m1 -E "^(${key})=" "$file" || true)"
    printf '%s' "${line#*=}"
}

tb_set_env_if_empty() {
    local key="$1"
    local value="$2"
    local file="$3"
    local temp_file

    temp_file="$(mktemp "${file}.XXXXXX")"
    awk -v key="$key" -v value="$value" '
        BEGIN { found = 0 }
        index($0, key "=") == 1 {
            found = 1
            if (substr($0, length(key) + 2) == "") print key "=" value
            else print
            next
        }
        { print }
        END { if (!found) print key "=" value }
    ' "$file" > "$temp_file"
    cat "$temp_file" > "$file"
    rm -f "$temp_file"
    chmod 600 "$file"
}

tb_prompt_value() {
    local prompt="$1"
    local default_value="$2"
    local value

    read -r -p "$prompt [$default_value]: " value
    printf '%s' "${value:-$default_value}"
}

tb_prepare_installation() {
    local install_dir base_url app_version db_version sidecar_version
    local env_file compose_file value

    install_dir="$(tb_prompt_value "Installation directory" "/opt/tech-bench")"
    [[ "$install_dir" == /* ]] || tb_die "Installation directory must be an absolute path."
    [[ "$install_dir" != *$'\n'* ]] || tb_die "Installation directory cannot contain a newline."

    if [[ -e "$install_dir" && ! -d "$install_dir" ]]; then
        tb_die "The selected installation path exists and is not a directory: $install_dir"
    fi

    if [[ ! -d "$install_dir" ]]; then
        mkdir -p "$install_dir"
        chmod 750 "$install_dir"
    fi

    env_file="${install_dir}/.env"
    compose_file="${install_dir}/docker-compose.yml"

    [[ ! -L "$env_file" ]] || tb_die "Refusing to modify a symbolic-link environment file: $env_file"
    [[ ! -L "$compose_file" ]] || tb_die "Refusing to replace a symbolic-link Compose file: $compose_file"

    if [[ ! -f "$compose_file" ]]; then
        install -m 0644 "${LIB_DIR}/../templates/docker-compose.yml" "$compose_file"
        tb_info "Installed the production Docker Compose file."
    else
        tb_info "Existing docker-compose.yml found; leaving it unchanged."
    fi

    if [[ ! -f "$env_file" ]]; then
        base_url="$(tb_prompt_value "Tech Bench hostname or IP address (without https://)" "")"
        [[ -n "$base_url" ]] || tb_die "A hostname or IP address is required."
        [[ "$base_url" =~ ^[A-Za-z0-9.-]+$ ]] || tb_die "Use a hostname or IPv4 address without a scheme, port, path, or spaces."

        umask 077
        awk -v base_url="$base_url" '
            /^BASE_URL=$/ { print "BASE_URL=" base_url; next }
            { print }
        ' "${LIB_DIR}/../templates/app.env.example" > "$env_file"
        chmod 600 "$env_file"
        tb_info "Created the initial application environment file."
    else
        chmod 600 "$env_file"
        base_url="$(tb_env_value BASE_URL "$env_file")"
        if [[ -z "$base_url" ]]; then
            base_url="$(tb_prompt_value "Tech Bench hostname or IP address (without https://)" "")"
            [[ -n "$base_url" ]] || tb_die "BASE_URL is empty. A hostname or IP address is required."
            [[ "$base_url" =~ ^[A-Za-z0-9.-]+$ ]] || tb_die "Use a hostname or IPv4 address without a scheme, port, path, or spaces."
            tb_set_env_if_empty BASE_URL "$base_url" "$env_file"
        else
            tb_info "Existing BASE_URL detected; preserving it."
        fi
    fi

    # Existing non-empty values are never replaced. Missing or blank Compose
    # variables receive safe defaults or newly generated secrets.
    app_version="$(tb_env_value APP_VERSION "$env_file")"
    [[ -n "$app_version" ]] || app_version="$(tb_prompt_value "Tech Bench application image tag" "latest")"
    db_version="$(tb_env_value DB_VERSION "$env_file")"
    [[ -n "$db_version" ]] || db_version="$(tb_prompt_value "Tech Bench database image tag" "latest")"
    sidecar_version="$(tb_env_value SIDECAR_VERSION "$env_file")"
    [[ -n "$sidecar_version" ]] || sidecar_version="$(tb_prompt_value "Docker Sidecar image tag" "latest")"

    for value in "$app_version" "$db_version" "$sidecar_version"; do
        [[ "$value" =~ ^[A-Za-z0-9._-]+$ ]] || tb_die "Image tags may contain only letters, numbers, dots, underscores, and hyphens."
    done

    tb_set_env_if_empty APP_VERSION "$app_version" "$env_file"
    tb_set_env_if_empty DB_VERSION "$db_version" "$env_file"
    tb_set_env_if_empty SIDECAR_VERSION "$sidecar_version" "$env_file"
    tb_set_env_if_empty COMPOSE_PROJECT_NAME "tech-bench" "$env_file"
    tb_set_env_if_empty DB_ROOT_PASSWORD "$(tb_random_secret)" "$env_file"
    tb_set_env_if_empty REDIS_PASSWORD "$(tb_random_secret)" "$env_file"
    tb_set_env_if_empty MEILI_MASTER_KEY "$(tb_random_secret)" "$env_file"

    TB_INSTALL_DIR="$install_dir"
    export TB_INSTALL_DIR

    tb_info "Installation directory prepared: $TB_INSTALL_DIR"
    tb_info "Environment file created or preserved with permissions restricted to root."
}
