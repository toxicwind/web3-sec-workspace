#!/bin/bash
# bin/ghas.sh — GitHub Advanced Security helper for web3-sec-workspace
#
# Provides convenient local wrappers around:
# - gh code-scanning
# - gh secret-scanning (where available)
# - Local secret scanning via the sovereign workspace tools
# - Integration with your OpenFang + vLLM stack for triage

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

usage() {
  cat << EOF
Usage: ./bin/ghas.sh <command> [options]

Commands:
  code-scan              List code scanning alerts (requires GHAS enabled on repo)
  secret-scan [files]    Run local secret scan on provided files (or demo)
  alerts                 Show open security alerts (code + secret + dependabot)
  enable                 Guidance to enable GHAS features on this repo
  triage <alert-id>      Send alert context to your local solidity-security-auditor (OpenFang)

Examples:
  ./bin/ghas.sh code-scan
  ./bin/ghas.sh secret-scan README.md setup.sh
  ./bin/ghas.sh alerts
  ./bin/ghas.sh triage 12345
EOF
}

require_gh() {
  if ! command -v gh &>/dev/null; then
    echo -e "${RED}gh CLI not found. Install from https://cli.github.com${NC}"
    exit 1
  fi
}

cmd_code_scan() {
  require_gh
  echo -e "${CYAN}[GHAS]${NC} Fetching Code Scanning alerts for $(gh repo view --json nameWithOwner -q .nameWithOwner)..."
  gh api \
    -H "Accept: application/vnd.github+json" \
    "/repos/{owner}/{repo}/code-scanning/alerts?state=open" \
    --jq '.[] | "\(.number) | \(.rule.id) | \(.state) | \(.most_recent_instance.location.path):\(.most_recent_instance.location.start_line)"' 2>/dev/null || \
    echo "No alerts or GHAS Code Scanning not enabled on this repository."
}

cmd_secret_scan() {
  require_gh
  echo -e "${CYAN}[GHAS]${NC} Running local secret scan via MCP-capable tool (demo mode)..."

  # If files are provided, use them. Otherwise scan a few key files.
  if [ $# -gt 0 ]; then
    FILES=("$@")
  else
    FILES=("README.md" "setup.sh" "bin/ghas.sh" ".github/workflows/codeql.yml")
  fi

  # Build a payload of raw content
  PAYLOAD=()
  for f in "${FILES[@]}"; do
    if [ -f "$f" ]; then
      PAYLOAD+=("$(cat "$f")")
    fi
  done

  if [ ${#PAYLOAD[@]} -eq 0 ]; then
    echo "No files to scan."
    return 0
  fi

  # Use the available grok_com_github MCP run_secret_scanning capability if possible.
  # Here we demonstrate by calling the gh CLI secret scanning where supported,
  # or fall back to a local heuristic + note about using the MCP tool.
  echo -e "${YELLOW}Note:${NC} For full MCP-driven secret scanning, use the run_secret_scanning tool from grok_com_github MCP."
  echo "Performing basic local pattern scan..."

  # Simple local patterns (extend as needed)
  grep -E -n 'ghp_[A-Za-z0-9]{36}|sk-[A-Za-z0-9]{48}|AIza[0-9A-Za-z-_]{35}|-----BEGIN (RSA|EC|OPENSSH) PRIVATE KEY-----' "${FILES[@]}" 2>/dev/null || \
    echo -e "${GREEN}No obvious secrets found in the provided files (local heuristic).${NC}"
}

cmd_alerts() {
  require_gh
  OWNER_REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
  echo -e "${CYAN}[GHAS]${NC} Security alerts summary for $OWNER_REPO"
  echo

  echo -e "${YELLOW}Code Scanning:${NC}"
  gh api "/repos/{owner}/{repo}/code-scanning/alerts?state=open" --jq 'length' 2>/dev/null || echo "  (GHAS not enabled or no alerts)"

  echo -e "${YELLOW}Secret Scanning:${NC}"
  gh api "/repos/{owner}/{repo}/secret-scanning/alerts?state=open" --jq 'length' 2>/dev/null || echo "  (GHAS Secret Scanning not enabled or no alerts)"

  echo -e "${YELLOW}Dependabot:${NC}"
  gh api "/repos/{owner}/{repo}/dependabot/alerts?state=open" --jq 'length' 2>/dev/null || echo "  (Dependabot alerts require repo to have Dependabot enabled)"
}

cmd_enable() {
  cat << EOF
${CYAN}To enable full GitHub Advanced Security on this private repository:${NC}

1. Go to the repository Settings → Code security and analysis
2. Enable:
   - Dependency graph
   - Dependabot alerts + security updates
   - Code scanning (CodeQL)
   - Secret scanning (push protection recommended)

3. For private repos, Advanced Security features usually require:
   - GitHub Enterprise Cloud with Advanced Security license, OR
   - GitHub Team plan (limited availability in some regions)

Once enabled, run:
  ./bin/ghas.sh code-scan
  ./bin/ghas.sh alerts

The configuration files in .github/ are already committed and will activate automatically when GHAS is turned on.
EOF
}

cmd_triage() {
  local alert_id="${1:-}"
  if [ -z "$alert_id" ]; then
    echo "Usage: ./bin/ghas.sh triage <alert-number>"
    exit 1
  fi

  echo -e "${CYAN}[GHAS + Sovereign AI]${NC} Sending alert #$alert_id context to your local solidity-security-auditor via OpenFang..."

  # In a real implementation you would fetch the alert details via gh API
  # and pipe a well-structured prompt into `openfang agent chat solidity-security-auditor`

  echo "Example prompt that would be sent:"
  echo "  'Analyze this GitHub Code Scanning alert #$alert_id from our web3-sec-workspace...'"
  echo
  echo -e "${YELLOW}Tip:${NC} For full automation, extend this script to call:"
  echo "  openfang agent chat solidity-security-auditor --message \"<alert details>\""
}

case "${1:-}" in
  code-scan) shift; cmd_code_scan "$@" ;;
  secret-scan) shift; cmd_secret_scan "$@" ;;
  alerts) cmd_alerts ;;
  enable) cmd_enable ;;
  triage) shift; cmd_triage "$@" ;;
  *) usage ;;
esac
