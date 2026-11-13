#!/usr/bin/env bash
#
# Pull and deploy the production Tech Bench Compose stack.
#

TB_COMPOSE_PROJECT_NAME="tech-bench"
TB_COMPOSE_FILE=""

tb_compose() {
    docker compose \
        --project-name "$TB_COMPOSE_PROJECT_NAME" \
        --project-directory "$TB_INSTALL_DIR" \
        --env-file "$TB_INSTALL_DIR/.env" \
        -f "$TB_COMPOSE_FILE" "$@"
}

tb_show_deployment_diagnostics() {
    tb_warn "Current Compose service status:"
    tb_compose ps || true

    tb_warn "Recent container logs (last 60 lines per service):"
    local service
    while IFS= read -r service; do
        [[ -n "$service" ]] || continue
        printf '\n--- %s ---\n' "$service" >&2
        tb_compose logs --no-color --tail 60 "$service" >&2 || true
    done < <(tb_compose config --services 2>/dev/null || true)
}

tb_deploy_tech_bench() {
    local base_url

    TB_COMPOSE_FILE="$TB_INSTALL_DIR/docker-compose.yml"
    [[ -f "$TB_COMPOSE_FILE" ]] || tb_die "Production Compose file not found: $TB_COMPOSE_FILE"
    [[ -f "$TB_INSTALL_DIR/.env" ]] || tb_die "Application environment file not found: $TB_INSTALL_DIR/.env"

    TB_COMPOSE_PROJECT_NAME="$(tb_env_value COMPOSE_PROJECT_NAME "$TB_INSTALL_DIR/.env")"
    TB_COMPOSE_PROJECT_NAME="${TB_COMPOSE_PROJECT_NAME:-tech-bench}"
    [[ "$TB_COMPOSE_PROJECT_NAME" =~ ^[a-z0-9_-]+$ ]] || tb_die "Invalid COMPOSE_PROJECT_NAME in .env."

    base_url="$(tb_env_value BASE_URL "$TB_INSTALL_DIR/.env")"
    [[ -n "$base_url" ]] || tb_die "BASE_URL is empty in the application environment file."

    tb_info "Validating the production Docker Compose configuration."
    if ! tb_compose config --quiet; then
        tb_die "Docker Compose configuration validation failed. Review .env and docker-compose.yml."
    fi

    tb_info "Pulling the Tech Bench application and supporting images. This may take several minutes."
    if ! tb_compose pull; then
        tb_show_deployment_diagnostics
        tb_die "One or more Docker images could not be pulled. No deployment success is reported."
    fi

    tb_info "Starting Tech Bench services in dependency order and waiting for health checks."
    tb_info "The installer will wait up to 15 minutes for the complete stack."
    if ! tb_compose up --detach --wait --wait-timeout 900; then
        tb_show_deployment_diagnostics
        tb_die "Tech Bench did not reach the required running/healthy state. Review the diagnostics above."
    fi

    tb_info "Compose reports all services running and all configured health checks passing."
    tb_info "Tech Bench installation URL: https://$base_url"
    tb_info "Persistent Docker volumes have been left in place."
}
