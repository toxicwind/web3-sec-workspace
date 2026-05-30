#!/usr/bin/env python3
"""
lint_all.py — Multi-engine smart contract audit aggregator
Sovereign Web3 Security Workspace (2026)

Features:
- Runs Slither, Aderyn, Solhint, SolidityGuard in sequence (or selected)
- Colored output + exit code aggregation
- JSON + Markdown report collection
- Graceful handling of missing tools
"""

import argparse
import json
import os
import subprocess
import sys
import time
from pathlib import Path
from typing import Callable, List, Tuple

# --- Terminal colors ---
RED = "\033[0;31m"
GREEN = "\033[0;32m"
YELLOW = "\033[1;33m"
CYAN = "\033[0;36m"
BOLD = "\033[1m"
NC = "\033[0m"

ROOT = Path(__file__).resolve().parent.parent
CONFIG_DIR = ROOT / "config"
REPORTS_DIR = ROOT / "reports"
REPORTS_DIR.mkdir(exist_ok=True)

ToolResult = Tuple[str, int, str]  # (name, returncode, summary)


def log(msg: str, color: str = CYAN) -> None:
    print(f"{color}[Lint]{NC} {msg}")


def run_tool(name: str, cmd: List[str], cwd: Path) -> ToolResult:
    log(f"Running {BOLD}{name}{NC}...")
    start = time.time()
    try:
        result = subprocess.run(
            cmd,
            cwd=cwd,
            capture_output=True,
            text=True,
            timeout=600,
        )
        duration = time.time() - start
        rc = result.returncode
        summary = f"exit={rc} time={duration:.1f}s"
        if rc != 0:
            log(f"{name} finished with issues ({summary})", YELLOW if rc == 1 else RED)
        else:
            log(f"{name} clean ({summary})", GREEN)
        # Persist raw stderr/stdout for forensics
        (REPORTS_DIR / f"{name.lower()}.log").write_text(
            f"CMD: {' '.join(cmd)}\nRC: {rc}\n\nSTDOUT:\n{result.stdout}\n\nSTDERR:\n{result.stderr}"
        )
        return name, rc, summary
    except FileNotFoundError:
        log(f"{name} not found in PATH — skipping", YELLOW)
        return name, 127, "missing"
    except subprocess.TimeoutExpired:
        log(f"{name} timed out after 10min", RED)
        return name, 124, "timeout"
    except Exception as e:
        log(f"{name} crashed: {e}", RED)
        return name, 1, str(e)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Run all available static analysis engines against a Solidity project"
    )
    parser.add_argument(
        "target",
        help="Path to the Solidity project root (containing contracts/ or src/)",
    )
    parser.add_argument(
        "--tools",
        default="slither,aderyn,solhint,solidityguard",
        help="Comma-separated list of tools to run",
    )
    parser.add_argument(
        "--parallel", action="store_true", help="Experimental: run tools concurrently"
    )
    args = parser.parse_args()

    target = Path(args.target).resolve()
    if not target.exists():
        print(f"Target does not exist: {target}", file=sys.stderr)
        return 2

    os.makedirs(REPORTS_DIR, exist_ok=True)
    tools = [t.strip().lower() for t in args.tools.split(",") if t.strip()]

    results: List[ToolResult] = []

    tool_runners: dict[str, Callable[[], ToolResult]] = {
        "slither": lambda: run_tool(
            "Slither",
            [
                "slither",
                str(target),
                "--config-file",
                str(CONFIG_DIR / "slither.config.json"),
                "--json",
                str(REPORTS_DIR / "slither.json"),
            ],
            target,
        ),
        "aderyn": lambda: run_tool(
            "Aderyn",
            ["aderyn", ".", "-o", str(REPORTS_DIR / "aderyn_report.md")],
            target,
        ),
        "solhint": lambda: run_tool(
            "Solhint",
            [
                "solhint",
                "--config",
                str(CONFIG_DIR / ".solhint.json"),
                "--max-warnings",
                "0",
                "contracts/**/*.sol",
                "src/**/*.sol",
            ],
            target,
        ),
        "solidityguard": lambda: run_tool(
            "SolidityGuard",
            [
                "docker",
                "run",
                "--rm",
                "-v",
                f"{target}:/contracts",
                "ghcr.io/alt-research/solidityguard:latest",
                "scan",
                "/contracts",
                "--format",
                "json",
                "--output",
                "/contracts/../reports/solidityguard.json",
            ],
            target,
        ),
    }

    for tool in tools:
        if tool in tool_runners:
            results.append(tool_runners[tool]())
        else:
            log(f"Unknown tool: {tool}", RED)

    # Summary
    print(f"\n{BOLD}════════════════ Summary ════════════════{NC}")
    total_errors = 0
    for name, rc, summary in results:
        status = "OK" if rc == 0 else "FAIL"
        color = GREEN if rc == 0 else RED
        print(f"  {color}{status:4}{NC}  {name:14} {summary}")
        if rc not in (0, 127):
            total_errors += 1

    print(f"\nReports written to: {REPORTS_DIR}")
    return min(total_errors, 255)


if __name__ == "__main__":
    sys.exit(main())
