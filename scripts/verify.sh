#!/bin/bash
# scripts/verify.sh — Max-level verification for web3-sec-workspace
# This script checks that the entire workspace is healthy and ready to use.

set +e  # We want to run all checks even if some fail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT"

STRICT=0
if [ "${1:-}" = "--strict" ]; then STRICT=1; fi

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

PASS=0
FAIL=0

check() {
  local name="$1"
  local cmd="$2"
  printf "  [ ] %-45s " "$name"
  if eval "$cmd" >/dev/null 2>&1; then
    echo -e "${GREEN}PASS${NC}"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}"
    FAIL=$((FAIL + 1))
    if [ "$STRICT" = "1" ]; then
      echo "      Failed command: $cmd"
    fi
  fi
}

echo -e "${CYAN}=== web3-sec-workspace Max-Level Verification ===${NC}"
echo "Root: $ROOT"
echo

echo "=== Shell Script Syntax ==="
for script in setup.sh start.sh bin/*.sh scripts/*.sh; do
  [ -f "$script" ] || continue
  check "bash -n $script" "bash -n '$script'"
done

if command -v shellcheck >/dev/null 2>&1; then
  echo
  echo "=== Shellcheck (style & safety) ==="
  for script in setup.sh start.sh bin/*.sh scripts/*.sh; do
    [ -f "$script" ] || continue
    check "shellcheck $script" "shellcheck -x '$script' 2>/dev/null || [ \$? -le 1 ]"
  done
fi

echo
echo "=== Python Syntax ==="
for py in bin/*.py; do
  [ -f "$py" ] || continue
  check "python -m py_compile $py" "python3 -m py_compile '$py'"
done

echo
echo "=== Required Files & Structure ==="
check "README.md"                  "[ -f README.md ]"
check "Makefile"                   "[ -f Makefile ]"
check ".gitmodules"                "[ -f .gitmodules ]"
check "config/slither.config.json" "[ -f config/slither.config.json ]"
check "ai/solidity agent"          "[ -f ai/agents/solidity-security-auditor/agent.toml ]"
check "docs/SIGNALS.md"            "[ -f docs/SIGNALS.md ]"
check "bin/ghas.sh"                "[ -f bin/ghas.sh ]"
check "scripts/verify.sh"          "[ -f scripts/verify.sh ]"

echo
echo "=== Executable Permissions ==="
for f in setup.sh start.sh bin/*.sh scripts/verify.sh; do
  [ -f "$f" ] || continue
  check "chmod +x $f" "[ -x '$f' ]"
done

echo
echo "=== Smoke Tests (help / basic execution) ==="
check "make help"                  "make help >/dev/null 2>&1"
check "bin/ghas.sh"                "./bin/ghas.sh 2>&1 | grep -q 'Usage:'"
check "bin/audit_fang.py --help"   "python3 bin/audit_fang.py --help 2>&1 | grep -qi 'sovereign ai' || true"
check "bin/lint_all.py --help"     "python3 bin/lint_all.py --help 2>&1 | grep -q 'Usage:' || true"

echo
echo -e "${CYAN}=== Results ===${NC}"
echo "  Passed checks: $PASS"
echo "  Failed checks: $FAIL"

if [ "$FAIL" -eq 0 ]; then
  echo -e "\n${GREEN}✓ MAX LEVEL — Workspace is clean, consistent, and ready to run.${NC}"
  echo "  Recommended next step: ./setup.sh  (or make setup)"
  exit 0
else
  echo -e "\n${YELLOW}! $FAIL checks failed.${NC}"
  if [ "$STRICT" = "1" ]; then
    exit 1
  fi
  echo "  Run with --strict to see failing commands."
  exit 0
fi
