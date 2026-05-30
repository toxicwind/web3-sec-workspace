#!/bin/bash
# start.sh — Activate the full sovereign Web3 security environment

set -euo pipefail

WORKSPACE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$WORKSPACE_ROOT"

# Activate Python venv if present
if [ -f "venv/bin/activate" ]; then
  # shellcheck disable=SC1091
  source venv/bin/activate
  echo -e "\033[0;32m[env]\033[0m Python venv activated"
fi

# Add local bin to PATH
export PATH="$WORKSPACE_ROOT/bin:$PATH"

cat << 'EOF'

   __        __   _     _____   ____     ____            __        __         _     _                 
   \ \      / /__| |__ |___ /  / ___|___/ ___|  ___  ___ \ \      / /__  _ __| | __| | ___  _ __  ___ 
    \ \ /\ / / _ \ '_ \  |_ \  \___ \ _ \___ \ / _ \/ __| \ \ /\ / / _ \| '__| |/ _` |/ _ \| '_ \/ __|
     \ V  V /  __/ |_) |___) |  ___) | | |__) |  __/ (__   \ V  V / (_) | |  | | (_| | (_) | | | \__ \
      \_/\_/ \___|_.__/|____/  |____/| |____/ \___|\___|   \_/\_/ \___/|_|  |_|\__,_|\___/|_| |_|___/
                                                                                                    
   Sovereign Web3 Security Audit Workspace — 2026
   Location: $WORKSPACE_ROOT

EOF

echo -e "\033[1mAvailable commands (add to your shell):\033[0m"
echo
echo "  Static Analysis"
echo "    slither <contract.sol>          # Trail of Bits analyzer"
echo "    aderyn .                        # Cyfrin Rust analyzer (fast)"
echo "    solhint 'contracts/**/*.sol'    # Solhint linter"
echo "    python bin/lint_all.py <dir>    # All engines + aggregator"
echo
echo "  Dynamic / Fuzzing"
echo "    forge test                      # Foundry (after cd workspace/...)"
echo "    echidna <contract> --config ... # Property-based fuzzer"
echo "    medusa ...                      # Go-based fuzzer"
echo
echo "  AI / Specialized (Sovereign stack)"
echo "    docker run --rm -v \$PWD:/contracts ghcr.io/alt-research/solidityguard:latest scan /contracts"
echo "    python bin/audit_fang.py <target> --agent security-auditor   # your local OpenFang + vLLM"
echo "    make fang TARGET=... AGENT=solidity-security-auditor"
echo
echo "  Workspace"
echo "    cd workspace/damn-vulnerable-defi && forge install && forge test"
echo "    make lint TARGET=workspace/damn-vulnerable-defi"
echo
echo -e "\033[2mTip: Run 'make help' for common workflows\033[0m"
echo

# Drop into interactive shell preserving env
exec "${SHELL:-/bin/bash}"
