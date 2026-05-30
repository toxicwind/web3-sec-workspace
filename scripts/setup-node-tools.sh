#!/bin/bash
# setup-node-tools.sh — Solhint + post-submodule builds for TS/JS tools
set -euo pipefail
source "$(dirname "$0")/lib.sh"

log_step "Node.js global tools + submodule native builds"

# Global linter
if ! command_exists solhint; then
  log_info "Installing Solhint globally..."
  npm install -g solhint
else
  log_dim "  Solhint already global"
fi

# Post-clone builds for submodules that ship TS sources
WORKSPACE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# honeypotscan
HONEYPOT_DIR="$WORKSPACE_ROOT/tools/honeypotscan"
if [ -d "$HONEYPOT_DIR" ]; then
  if [ -f "$HONEYPOT_DIR/package.json" ]; then
    log_info "Building honeypotscan..."
    (cd "$HONEYPOT_DIR" && npm install --silent && npm run build --if-present) || log_warn "honeypotscan build had issues"
  fi
fi

# solql intentionally omitted — upstream (0xJasonn/solql) unavailable at workspace creation time.
# If the repository returns, re-add as: git submodule add https://github.com/0xJasonn/solql.git tools/solql
log_dim "  solql: upstream not present (see tools/solql/README.md if created)"

log_success "Node tooling layer ready"
