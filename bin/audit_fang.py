#!/usr/bin/env python3
"""
audit_fang.py — Sovereign AI audit pass using your local OpenFang + vLLM stack.

This replaces the old generic third-party "AI scanner" Python packages.

It feeds contract source + prior classical tool output into your running
security-auditor (or solidity-security-auditor) agent and captures the response.

Usage:
    python bin/audit_fang.py workspace/damn-vulnerable-defi --agent security-auditor
    python bin/audit_fang.py path/to/contracts --agent solidity-security-auditor --max-files 30
"""

import argparse
import json
import os
import subprocess
import sys
import time
from pathlib import Path
from typing import List, Optional

ROOT = Path(__file__).resolve().parent.parent
REPORTS = ROOT / "reports"
REPORTS.mkdir(exist_ok=True)

OPENFANG_API = os.environ.get("OPENFANG_API", "http://127.0.0.1:14720")
OPENFANG_BIN = os.environ.get("OPENFANG_BIN", os.path.expanduser("~/.local/bin/openfang"))


def log(msg: str, color: str = "\033[0;36m") -> None:
    print(f"{color}[Fang]{'\033[0m'} {msg}")


def find_solidity_files(target: Path, max_files: int = 50) -> List[Path]:
    exts = {".sol"}
    files: List[Path] = []
    for p in target.rglob("*"):
        if p.is_file() and p.suffix in exts:
            # Skip obvious test/mocks unless user really wants them
            if any(x in p.parts for x in ("test", "tests", "mock", "mocks", "node_modules")):
                continue
            files.append(p)
            if len(files) >= max_files:
                break
    return files


def build_context(target: Path, max_files: int) -> str:
    files = find_solidity_files(target, max_files)
    log(f"Collected {len(files)} Solidity files for AI context")

    parts = []
    for f in files[:max_files]:
        try:
            content = f.read_text(encoding="utf-8", errors="ignore")
            parts.append(f"=== FILE: {f.relative_to(target)} ===\n{content}\n")
        except Exception as e:
            parts.append(f"=== FILE: {f} (read error: {e}) ===\n")

    # Also pull in any recent classical tool reports if they exist
    for report_name in ("slither.json", "aderyn_report.md", "lint_all.log"):
        rp = REPORTS / report_name
        if rp.exists():
            try:
                parts.append(f"\n=== PRIOR TOOL OUTPUT: {report_name} ===\n{rp.read_text()[:8000]}\n")
            except Exception:
                pass

    return "\n".join(parts)


def call_openfang_cli(agent_name: str, prompt: str, timeout: int = 180) -> str:
    """Use the OpenFang CLI to chat with a specific agent (best for local use)."""
    if not os.path.exists(OPENFANG_BIN):
        raise RuntimeError(f"openfang binary not found at {OPENFANG_BIN}")

    # We use a non-interactive one-shot via the chat mechanism if available,
    # otherwise we fall back to spawning a temporary session.
    # Simpler reliable path: use `openfang chat` with injected context is tricky.
    # Better: use the agent chat subcommand with a one-off message.

    cmd = [
        OPENFANG_BIN, "agent", "chat", agent_name,
        "--message", prompt[:120_000],   # safety
        "--no-stream",
    ]

    log(f"Invoking OpenFang agent '{agent_name}' via CLI (timeout {timeout}s)...")
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout,
        )
        if result.returncode != 0:
            log(f"OpenFang CLI returned {result.returncode}", "\033[0;31m")
            log(result.stderr[-2000:], "\033[0;31m")
        return result.stdout or result.stderr or "(no output)"
    except subprocess.TimeoutExpired:
        return "[TIMEOUT] OpenFang agent did not respond in time. The finding may still be processing in the daemon."


def main() -> int:
    parser = argparse.ArgumentParser(description="Run sovereign AI audit via local OpenFang + vLLM")
    parser.add_argument("target", help="Directory containing Solidity contracts")
    parser.add_argument("--agent", default="security-auditor",
                        help="OpenFang agent name to use (default: security-auditor)")
    parser.add_argument("--max-files", type=int, default=40,
                        help="Maximum number of .sol files to include in context")
    parser.add_argument("--timeout", type=int, default=180)
    args = parser.parse_args()

    target = Path(args.target).resolve()
    if not target.exists():
        print(f"Target not found: {target}", file=sys.stderr)
        return 2

    context = build_context(target, args.max_files)

    system_instruction = (
        "You are performing a deep security review of the following Solidity/EVM codebase. "
        "Previous classical analysis results are included where available. "
        "Focus on novel, high-severity issues. Be specific and actionable.\n\n"
    )

    full_prompt = system_instruction + context + "\n\n---\nProduce your audit report now."

    try:
        response = call_openfang_cli(args.agent, full_prompt, args.timeout)
    except Exception as e:
        log(f"Failed to reach OpenFang: {e}", "\033[0;31m")
        return 1

    out_path = REPORTS / f"fang_{args.agent}_{int(time.time())}.md"
    out_path.write_text(
        f"# Sovereign AI Audit — {args.agent}\n\n"
        f"Target: {target}\n"
        f"Timestamp: {time.strftime('%Y-%m-%d %H:%M:%S')}\n\n"
        f"## Findings\n\n{response}\n"
    )

    log(f"AI audit saved to {out_path}", "\033[0;32m")
    print(response[:4000])  # show head in terminal
    return 0


if __name__ == "__main__":
    sys.exit(main())
