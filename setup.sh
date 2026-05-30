#!/bin/bash
# setup.sh — Sovereign Web3 Security Workspace bootstrap (2026 modular edition)
#
# Usage:
#   git clone --recurse-submodules https://github.com/toxicwind/web3-sec-workspace.git ~/web3-sec-workspace
#   cd ~/web3-sec-workspace
#   ./setup.sh
#
# This script is idempotent and safe to re-run.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/lib.sh"

cd "$SCRIPT_DIR"

print_banner

echo
log_info "Workspace root: $SCRIPT_DIR"
log_info "Distro: $(detect_distro)"
echo

# --- Pre-flight ---
if [ ! -d "scripts" ] || [ ! -d "config" ]; then
  log_error "This does not look like the web3-sec-workspace root. Aborting."
  exit 1
fi

# Make everything executable
find "$SCRIPT_DIR" -name "*.sh" -exec chmod +x {} \;
chmod +x "$SCRIPT_DIR/bin/"* 2>/dev/null || true

# --- Modules (order matters) ---
bash "$SCRIPT_DIR/scripts/setup-system.sh"
bash "$SCRIPT_DIR/scripts/setup-python.sh"
bash "$SCRIPT_DIR/scripts/setup-fuzzers.sh"
bash "$SCRIPT_DIR/scripts/setup-docker.sh"
bash "$SCRIPT_DIR/scripts/setup-submodules.sh"
bash "$SCRIPT_DIR/scripts/setup-sovereign-ai.sh"

echo
log_success "═══════════════════════════════════════════════════════════════"
log_success "  Workspace bootstrap complete"
log_success "═══════════════════════════════════════════════════════════════"
echo
log_info "Next steps:"
echo "  1. (Recommended) log out and back in so docker group takes effect"
echo "  2. cd ~/web3-sec-workspace && ./start.sh"
echo "  3. Try: python bin/lint_all.py workspace/damn-vulnerable-defi"
echo "  4. Try: python bin/audit_fang.py workspace/damn-vulnerable-defi --agent security-auditor"
echo "  5. Or: make help"
echo
log_dim "Classical tools (Slither, Aderyn, Foundry, Echidna...) + your local OpenFang + vLLM sovereign AI stack are ready."
