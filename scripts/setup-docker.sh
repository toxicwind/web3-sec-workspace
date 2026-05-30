#!/bin/bash
# setup-docker.sh — Pull official security container images
set -euo pipefail
source "$(dirname "$0")/lib.sh"

log_step "Docker security images"

if ! command_exists docker; then
  log_error "Docker not found — run setup-system.sh first"
  exit 1
fi

log_info "Pulling SolidityGuard (Alt-Research)..."
docker pull ghcr.io/alt-research/solidityguard:latest || log_warn "SolidityGuard pull failed (network or auth?)"

# Future-proof: add more heavy images here (e.g. mythril docker variant, etc.)
# docker pull trailofbits/echidna ...

log_success "Docker images ready"
