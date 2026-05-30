#!/bin/bash
# setup-fuzzers.sh — Foundry + property-based + symbolic fuzzers
set -euo pipefail
source "$(dirname "$0")/lib.sh"

log_step "Foundry + Fuzzers (Echidna / Medusa / Mythril already in Python)"

# Foundry (Paradigm) — the 2024-2026 standard
if ! command_exists forge; then
  log_info "Installing Foundry toolchain..."
  curl -L https://foundry.paradigm.xyz | bash
  # shellcheck disable=SC1090
  source "$HOME/.bashrc" 2>/dev/null || true
  # foundryup may be in PATH now
  if command_exists foundryup; then
    foundryup
  else
    # common fallback location
    "$HOME/.foundry/bin/foundryup" || log_warn "Run 'foundryup' manually after setup"
  fi
else
  log_dim "  Foundry already present (forge/cast/anvil)"
fi

# Echidna & Medusa via cargo (crytic + medusa)
if ! command_exists echidna; then
  log_info "Installing Echidna (cargo)..."
  cargo install echidna || log_warn "Echidna cargo install can be slow or require specific Rust version"
else
  log_dim "  Echidna present"
fi

if ! command_exists medusa; then
  log_info "Installing Medusa fuzzer (cargo)..."
  cargo install medusa || log_warn "Medusa install failed — check https://github.com/crytic/medusa"
else
  log_dim "  Medusa present"
fi

log_success "Fuzzing layer ready"
