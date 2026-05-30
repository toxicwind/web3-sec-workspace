#!/bin/bash
# setup-submodules.sh — Ensure all Git submodules are checked out + built where needed
set -euo pipefail
source "$(dirname "$0")/lib.sh"

log_step "Git submodules initialization"

WORKSPACE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$WORKSPACE_ROOT"

if [ ! -f .gitmodules ]; then
  log_warn "No .gitmodules found — skipping (you may be in a shallow copy)"
  exit 0
fi

log_info "Updating submodules (shallow where possible)..."
git submodule update --init --recursive --depth 1 --jobs 4 || log_warn "Some submodules may need manual 'git submodule update --init'"

# Run the Node builds again in case user ran setup before submodules were populated
bash "$(dirname "$0")/setup-node-tools.sh" || true

log_success "Submodules initialized"
log_dim "  Tip: git submodule update --remote --merge   to pull latest tool versions"
