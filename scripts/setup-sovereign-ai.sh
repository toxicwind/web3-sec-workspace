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

# --- Seed a workspace-specific Solidity-tuned agent manifest ---
AI_AGENTS_DIR="${WORKSPACE_ROOT}/ai/agents"
SOLIDITY_AGENT_DIR="${AI_AGENTS_DIR}/solidity-security-auditor"
mkdir -p "$SOLIDITY_AGENT_DIR"

if [ ! -f "$SOLIDITY_AGENT_DIR/agent.toml" ]; then
  log_info "Seeding high-quality solidity-security-auditor agent manifest..."
  cat > "$SOLIDITY_AGENT_DIR/agent.toml" << 'AGENTEOF'
name = "solidity-security-auditor"
version = "0.2.0"
description = "EVM/Solidity/DeFi specialist. Deep analysis of smart contract vulnerabilities, economic attacks, and protocol invariants. Works best with prior classical tool output (Slither, Aderyn, Foundry traces)."
author = "web3-sec-workspace"
module = "builtin:chat"
tags = ["solidity", "evm", "defi", "security", "audit", "smart-contracts"]

[model]
provider = "vllm"
model = "vllm-local"
api_key_env = "VLLM_API_KEY"
max_tokens = 8192
temperature = 0.15

system_prompt = """You are a world-class Solidity & EVM security researcher operating inside OpenFang.

You are given:
- Source code of one or more .sol contracts
- Output from classical tools (Slither detectors, Aderyn, Solhint, Foundry test traces, etc.)

Your job is to:
1. Identify high-impact, realistic attack vectors that the static tools are likely to have missed or under-rated.
2. Focus especially on:
   - Economic / game-theoretic attacks (flash-loan, oracle manipulation, governance takeovers, MEV extraction)
   - Incorrect access control patterns (missing modifiers, tx.origin, role escalation)
   - Reentrancy in all its modern forms (including read-only reentrancy, cross-function)
   - Storage layout / proxy / delegatecall / initializer issues
   - Arithmetic edge cases under EIP-712, Permit, and custom accounting
   - Invariant violations that only appear under specific call sequences or block conditions
3. For every finding provide: Severity (CRITICAL/HIGH/MEDIUM), title, affected contracts/functions, step-by-step attack scenario, and recommended fix + test idea.
4. When possible, suggest concrete invariant tests or fuzzing properties that should be added to the Foundry test suite.

Be precise, cite specific line numbers or function names when possible, and avoid generic "use SafeMath" advice unless actually relevant. Think like a top-tier auditor who has already seen the classical tool output."""

[capabilities]
tools = ["file_read", "file_list", "shell_exec", "memory_store", "memory_recall"]
memory_read = ["*"]
memory_write = ["self.*", "shared.*"]
shell = ["forge test *", "slither *", "aderyn *", "echidna *"]

[[fallback_models]]
provider = "vllm"
model = "vllm-local"
AGENTEOF
  log_success "Seeded ai/agents/solidity-security-auditor/agent.toml"
else
  log_dim "  solidity-security-auditor manifest already present"
fi

log_info "To import the Solidity auditor into your main OpenFang instance:"
log_info "  cp -r ${SOLIDITY_AGENT_DIR} ~/.openfang/agents/"
log_info "  openfang agent spawn ${SOLIDITY_AGENT_DIR}/agent.toml   # or use the TUI"

log_success "Sovereign AI layer ready — classical tools + your local OpenFang/vLLM stack"
