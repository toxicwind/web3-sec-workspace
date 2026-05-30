#!/bin/bash
# setup-system.sh — Base system dependencies + services (Arch optimized)
set -euo pipefail
source "$(dirname "$0")/lib.sh"

log_step "System dependencies & services"

distro=$(detect_distro)
log_info "Detected distro family: $distro"

# Core build + runtime
PACKAGES=(
  base-devel curl wget git jq
  python python-pip python-virtualenv
  nodejs npm
  rust cargo
  go cmake
  docker docker-compose
)

for pkg in "${PACKAGES[@]}"; do
  install_pkg "$pkg"
done

# Enable Docker (idempotent)
if command_exists docker; then
  if ! systemctl is-enabled docker &>/dev/null; then
    log_info "Enabling and starting Docker..."
    sudo systemctl enable docker --now
  else
    log_dim "  Docker service already enabled"
  fi
  # Add current user to docker group if needed (requires re-login)
  if ! groups | grep -q docker; then
    log_warn "Add yourself to docker group: sudo usermod -aG docker $USER  (then re-login)"
  fi
fi

log_success "System layer ready"
