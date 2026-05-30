#!/bin/bash
# setup-python.sh — Python venv + heavy security tooling
set -euo pipefail
source "$(dirname "$0")/lib.sh"

log_step "Python virtual environment & audit packages"

VENV_DIR="$(cd "$(dirname "$0")/.." && pwd)/venv"
PYTHON_BIN="${VENV_DIR}/bin/python"

if [ ! -d "$VENV_DIR" ]; then
  log_info "Creating Python venv at $VENV_DIR"
  python3 -m venv "$VENV_DIR"
else
  log_dim "  Venv already exists"
fi

# shellcheck disable=SC1091
source "${VENV_DIR}/bin/activate"

log_info "Upgrading pip + core build tools..."
pip install --upgrade pip setuptools wheel --quiet

# Core static + dynamic analysis (classical tools only)
log_info "Installing Slither + Mythril (classical analysis)..."
pip install --upgrade \
  slither-analyzer \
  slither-analyzer[evm] \
  mythril \
  --quiet 2>/dev/null || log_warn "Some Python packages may have optional dep issues"

log_dim "  Sovereign AI (OpenFang + vLLM) integration is handled by setup-sovereign-ai.sh"
log_dim "  Generic third-party AI scanners (agentarc, miesc, etc.) are intentionally skipped."

log_success "Python environment ready (source venv/bin/activate to use)"
