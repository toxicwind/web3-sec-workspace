#!/bin/bash
# setup-python.sh — Python venv + heavy security tooling
set -euo pipefail
source "$(dirname "$0")/lib.sh"

log_step "Python virtual environment & audit packages"

VENV_DIR="$(cd "$(dirname "$0")/.." && pwd)/venv"

if [ ! -d "$VENV_DIR" ]; then
  log_info "Creating Python venv at $VENV_DIR"
  python3 -m venv "$VENV_DIR"
else
  log_dim "  Venv already exists"
fi

# shellcheck disable=SC1091
source "${VENV_DIR}/bin/activate"

log_info "Upgrading pip + core build tools (idempotent)..."
pip install --upgrade pip setuptools wheel --quiet

# Core static + dynamic analysis (classical tools only) - smart check
NEED_PYTHON_REINSTALL=0
for pkg in slither-analyzer mythril; do
  if ! python -c "import ${pkg%%-*}" 2>/dev/null && ! python -c "import ${pkg}" 2>/dev/null; then
    NEED_PYTHON_REINSTALL=1
  fi
done

if [ "$NEED_PYTHON_REINSTALL" = "1" ]; then
  log_info "Installing/upgrading Slither + Mythril (classical analysis)..."
  pip install --upgrade \
    slither-analyzer \
    slither-analyzer[evm] \
    mythril \
    --quiet 2>/dev/null || log_warn "Some Python packages may have optional dep issues"
else
  log_dim "  Slither + Mythril already present in venv"
fi

log_dim "  Sovereign AI (OpenFang + vLLM) integration is handled by setup-sovereign-ai.sh"
log_dim "  Generic third-party AI scanners (agentarc, miesc, etc.) are intentionally skipped."

log_success "Python environment ready (source venv/bin/activate to use)"
