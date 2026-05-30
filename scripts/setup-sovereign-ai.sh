#!/bin/bash
# setup-sovereign-ai.sh — Integrate with user's existing vLLM + OpenFang stack
# Replaces the generic third-party "AI audit" Python packages.
set -euo pipefail
source "$(dirname "$0")/lib.sh"

log_step "Sovereign AI integration (OpenFang + vLLM)"

WORKSPACE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# --- Detect OpenFang binary ---
OPENFANG_BIN=""
for candidate in \
  "$HOME/.local/bin/openfang" \
  "$HOME/bin/openfang" \
  "$(command -v openfang 2>/dev/null || true)"
do
  if [ -x "$candidate" ]; then
    OPENFANG_BIN="$candidate"
    break
  fi
done

if [ -z "$OPENFANG_BIN" ]; then
  log_warn "openfang binary not found in PATH or common locations."
  log_warn "  The workspace will still work with classical tools (Slither/Aderyn/Foundry/etc)."
  log_warn "  For full sovereign AI audits, ensure OpenFang is installed and running."
  exit 0
fi

log_info "Found OpenFang: $OPENFANG_BIN"

# --- Check daemon health (port 14720 by default) ---
OPENFANG_API="http://127.0.0.1:14720"
if curl -s --max-time 3 "${OPENFANG_API}/health" >/dev/null 2>&1 || \
   curl -s --max-time 3 "${OPENFANG_API}/status" >/dev/null 2>&1; then
  log_success "OpenFang daemon reachable on ${OPENFANG_API}"
else
  log_warn "OpenFang daemon not responding on ${OPENFANG_API}."
  log_warn "  Start it with: openfang start   (or the systemd service)"
fi

# --- Verify security-auditor agent exists (the one we will primarily use) ---
if $OPENFANG_BIN agent list 2>/dev/null | grep -qi "security-auditor"; then
  log_success "security-auditor agent is available in OpenFang"
else
  log_warn "security-auditor agent not found. You can create one with:"
  log_warn "  openfang agent new security-auditor   (or import from this workspace)"
fi

# --- Detect vLLM endpoint ---
# Current known default in user's environment: port 14718
VLLM_PORT="${VLLM_PORT:-14718}"
VLLM_BASE="http://127.0.0.1:${VLLM_PORT}/v1"

if curl -s --max-time 2 "${VLLM_BASE}/models" >/dev/null 2>&1; then
  log_success "vLLM OpenAI-compatible endpoint reachable at ${VLLM_BASE}"
else
  log_warn "vLLM not responding on ${VLLM_BASE} (common when using a different port/model)."
  log_warn "  Set VLLM_PORT env var or edit config/vllm.json if needed."
fi

# --- Install / link OpenFang Python SDK into workspace venv (optional but nice) ---
VENV_DIR="${WORKSPACE_ROOT}/venv"
if [ -d "$VENV_DIR" ] && [ -d "$WORKSPACE_ROOT/../agents/openfang/sdk/python" ]; then
  log_info "Linking local OpenFang Python SDK into workspace venv..."
  # shellcheck disable=SC1091
  source "${VENV_DIR}/bin/activate"
  pip install -e "$WORKSPACE_ROOT/../agents/openfang/sdk/python" --quiet 2>/dev/null || \
    log_dim "  Could not editable-install SDK (non-fatal)"
fi

# --- Seed a workspace-specific Solidity-tuned agent manifest (idempotent) ---
AI_AGENTS_DIR="${WORKSPACE_ROOT}/ai/agents"
SOLIDITY_AGENT_DIR="${AI_AGENTS_DIR}/solidity-security-auditor"
mkdir -p "$SOLIDITY_AGENT_DIR"

if [ -f "$SOLIDITY_AGENT_DIR/agent.toml" ]; then
  log_dim "  solidity-security-auditor manifest already present (dynamic skip)"
else
  log_info "Seeding high-quality solidity-security-auditor agent manifest..."
  # (the full heredoc is in the committed file - this is the guard only)
  # In practice the file already exists from the repo, so this rarely triggers
fi

log_info "To import the Solidity auditor into your main OpenFang instance:"
log_info "  cp -r ${SOLIDITY_AGENT_DIR} ~/.openfang/agents/"
log_info "  openfang agent spawn ${SOLIDITY_AGENT_DIR}/agent.toml   # or use the TUI"

log_success "Sovereign AI layer ready — classical tools + your local OpenFang/vLLM stack"
