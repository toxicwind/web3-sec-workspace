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

# Post-clone builds for submodules that ship TS sources (dynamic - skip if already built)
WORKSPACE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# honeypotscan
HONEYPOT_DIR="$WORKSPACE_ROOT/tools/honeypotscan"
if [ -d "$HONEYPOT_DIR" ] && [ -f "$HONEYPOT_DIR/package.json" ]; then
  if [ -d "$HONEYPOT_DIR/dist" ] || [ -f "$HONEYPOT_DIR/build/index.js" ]; then
    log_dim "  honeypotscan already built (dist/ exists)"
  else
    log_info "Building honeypotscan (first run or clean)..."
    (cd "$HONEYPOT_DIR" && npm install --silent && npm run build --if-present) || log_warn "honeypotscan build had issues"
  fi
fi

# solql intentionally omitted — upstream (0xJasonn/solql) unavailable at workspace creation time.
log_dim "  solql: upstream not present (see tools/solql/README.md if created)"

log_success "Node tooling layer ready"
