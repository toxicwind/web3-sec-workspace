# web3-sec-workspace

> **Public. Sovereign. 2026-grade.**  
> A self-contained, reproducible smart contract security laboratory that lives entirely on your machine.

<p align="center">
  <img src="https://img.shields.io/badge/Solidity-363636?style=for-the-badge&logo=solidity&logoColor=white" alt="Solidity">
  <img src="https://img.shields.io/badge/Foundry-FF6B35?style=for-the-badge&logo=ethereum&logoColor=white" alt="Foundry">
  <img src="https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white" alt="Python">
  <img src="https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Docker">
  <img src="https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white" alt="Arch">
  <img src="https://img.shields.io/badge/license-MIT-blue?style=for-the-badge" alt="MIT">
</p>

---

## TL;DR

```bash
git clone --recurse-submodules https://github.com/toxicwind/web3-sec-workspace.git ~/web3-sec-workspace
cd ~/web3-sec-workspace
./setup.sh          # one-time, idempotent (grab coffee on first run)
./start.sh          # drops you into the activated environment
make lint TARGET=workspace/damn-vulnerable-defi
```

Everything — static analysis, fuzzing, AI scanners, containers — runs locally. Your contracts never leave the machine.

---

## Why This Exists

Most audit stacks are fragmented, cloud-dependent, or require 11 different GitHub accounts. This workspace solves that with ruthless integration:

- One command environment bootstrap
- Git submodules pin every external tool at a known-good state
- Unified configuration surface (`config/`)
- Single aggregator that orchestrates the entire engine fleet
- Damn Vulnerable DeFi as a first-class, always-available practice target
- Makefile + beautiful scripts for muscle-memory workflows

---

## Audit Pipeline (Classical + Sovereign AI)

```mermaid
flowchart LR
    A[Your Contracts<br/>or Submodule Target] --> B{Static Analysis Fleet}
    B -->|Slither| C[Trail of Bits<br/>Symbolic + Detectors]
    B -->|Aderyn| D[Cyfrin Rust<br/>Blazing Fast]
    B -->|Solhint| E[Linter Rules]
    B -->|SolidityGuard| F[Alt-Research<br/>Docker ML]
    
    G[Fuzzing Layer] -->|Echidna| H[Property Based]
    G -->|Medusa| I[Go Fuzzer]
    G -->|Foundry Invariants| J[forge test --invariant]
    
    K[Sovereign AI] -->|OpenFang security-auditor + solidity-security-auditor| L[Your local vLLM models]
    K -->|Krait / RugProof heuristics (optional)| M[Local pattern matching]
    K -->|Honeypotscan| N[Token Safety]
    
    C & D & E & F & H & I & J & L & M & N --> O[reports/]
    O --> P[lint_all.py<br/>Aggregator + Exit Codes]
    P --> Q[Human Review + Custom Rules]
```

---

## Toolchain Matrix

| Category          | Tool                  | Type                  | Command Example                              | Notes |
|-------------------|-----------------------|-----------------------|----------------------------------------------|-------|
| Static            | **Slither**           | Symbolic + Detectors  | `slither . --config ...`                     | Gold standard |
| Static (Fast)     | **Aderyn**            | Rust AST              | `aderyn .`                                   | Extremely fast, modern |
| Linter            | **Solhint**           | Style + Security      | `solhint 'src/**/*.sol'`                     | Configured for gas + visibility |
| Container ML      | **SolidityGuard**     | Docker + ML           | `docker run ... solidityguard scan`          | Alt-Research |
| Fuzzing           | **Echidna**           | Property-based        | `echidna contract.sol`                       | Trail of Bits |
| Fuzzing           | **Medusa**            | Go fuzzer             | `medusa fuzz`                                | High throughput |
| Dev / Testing     | **Foundry**           | forge/cast/anvil      | `forge test --invariant`                     | Mandatory |
| Symbolic          | **Mythril**           | Symbolic execution    | `myth analyze contract.sol`                  | Via venv |
| Sovereign AI      | **OpenFang + vLLM**   | Your local agent OS   | `python bin/audit_fang.py . --agent security-auditor` | See ai/agents/ + ~/.openfang |
| Token Safety      | **honeypotscan**      | Honeypot / rug        | `cd tools/honeypotscan && npm run dev`       | Built from submodule |
| Sovereign AI Core | **OpenFang + vLLM**   | Your local agent OS   | `python bin/audit_fang.py . --agent security-auditor` | Fully local (port 14720) |
| Heuristics        | **Krait / RugProof**  | Optional pattern libs | (see tools/krait, tools/RugProof)            | Submodules |
| Query             | **solql**             | Solidity query lang   | *(upstream unavailable at 2026 creation)*    | See tools/solql/README.md |

---

## Directory Layout

```
web3-sec-workspace/
├── bin/
│   └── lint_all.py          # Multi-engine orchestrator
├── config/
│   ├── slither.config.json
│   ├── aderyn.config.toml
│   └── .solhint.json
├── scripts/                 # Modular bootstrap (the real magic)
│   ├── lib.sh
│   ├── setup-*.sh
│   └── setup-submodules.sh
├── tools/                   # Git submodules (pinned)
│   ├── krait/
│   ├── RugProof/
│   ├── honeypotscan/
│   └── solql/              # placeholder (upstream unavailable at creation)
├── workspace/
│   └── damn-vulnerable-defi/   # Practice CTF target (submodule)
├── reports/                 # Gitignored — your findings live here
├── logs/                    # Gitignored
├── Makefile
├── setup.sh
├── start.sh
├── .env.example             # Documented environment variables (copy to .env)
└── .gitmodules
```

## Configuration & Secrets

This workspace is **secret-hygiene first**.

- `.env` and all `.env.*` files are **gitignored** (see `.gitignore`).
- Never commit real API keys, private keys, RPC credentials, or GitHub tokens.
- A comprehensive template lives at **`.env.example`** at the root. Copy it:

  ```bash
  cp .env.example .env
  # then edit .env with your values
  ```

Key variable families:
- **Sovereign AI**: `OPENFANG_API`, `OPENFANG_BIN`, `VLLM_PORT`, `VLLM_API_KEY` (used by `bin/audit_fang.py` and the solidity-security-auditor agent).
- **Blockchain data**: `ETHERSCAN_API_KEY` (and `_1` through `_6` for rate-limit pooling — used heavily by honeypotscan and GHAS tooling).
- **GitHub**: `GITHUB_TOKEN` (for `bin/ghas.sh` and MCP secret scanning).

Sub-tools may have additional `.env.example` files (e.g. `tools/honeypotscan/.env.example`). The root one is the single source of truth for shared values.

See also:
- `scripts/setup-sovereign-ai.sh` (how the local stack is detected)
- `docs/SIGNALS.md`
- `ai/agents/solidity-security-auditor/agent.toml`

---



## Sovereign AI Layer (OpenFang + vLLM) + GitHub Advanced Security

This workspace is designed as a **companion** to your existing sovereign stack rather than pulling in random third-party AI scanners.

Additional integration: Full **GitHub Advanced Security (GHAS)** support has been added using the available `grok_com_github` MCP tooling (including `run_secret_scanning`).

See:
- `.github/workflows/codeql.yml`
- `bin/ghas.sh` (convenient local wrapper)

- Your running `security-auditor` agent (and the workspace-seeded `solidity-security-auditor`) are the primary AI reviewers.
- They talk to whatever model(s) you are currently serving with vLLM (currently Qwen2.5 on port 14718 in your environment).
- Classical tools (Slither, Aderyn, Foundry, Echidna...) still run locally and their output can be fed as context into the agents.

### Quick AI Audit

```bash
python bin/audit_fang.py workspace/damn-vulnerable-defi --agent security-auditor
# or the nicer Makefile target
make fang TARGET=workspace/damn-vulnerable-defi AGENT=solidity-security-auditor
```

Findings are written to `reports/fang_*.md`.

### Bringing the better Solidity agent into your main OpenFang

```bash
cp -r ai/agents/solidity-security-auditor ~/.openfang/agents/
openfang agent spawn ~/.openfang/agents/solidity-security-auditor/agent.toml
```

The prompt is heavily tuned for EVM/DeFi realities (flash loans, read-only reentrancy, storage collisions, custom accounting, etc.) and expects prior classical tool output.

---

## Installation (Full Sovereign Path)

### 1. Clone with submodules (critical)

```bash
git clone --recurse-submodules \
  https://github.com/toxicwind/web3-sec-workspace.git \
  ~/web3-sec-workspace
cd ~/web3-sec-workspace
```

> [!IMPORTANT]  
> Omitting `--recurse-submodules` will leave `tools/` and `workspace/damn-vulnerable-defi` empty.

### 2. Bootstrap

```bash
./setup.sh
```

This runs the modular layers in order:
- System packages (pacman-first, best-effort on Debian)
- Python venv + Slither / Mythril
- Sovereign AI integration with your running OpenFang + vLLM (security-auditor + custom solidity agent)
- Foundry + Echidna + Medusa
- Docker images (SolidityGuard)
- Submodule checkout + post-build for TS tools

### 3. Activate

```bash
./start.sh
# or
make start
```

You are now inside an environment where every tool is on PATH and the venv is active.

---

## Daily Usage

### Run the full fleet against any target

```bash
make lint TARGET=workspace/damn-vulnerable-defi
# or directly
python bin/lint_all.py workspace/damn-vulnerable-defi
```

Reports land in `reports/`.

### Sovereign AI + Zero-Day Signal Hunting

```bash
make fang TARGET=workspace/damn-vulnerable-defi -- AGENT=solidity-security-auditor
```

See the full **🧠 终极整合** vision, exploitation matrix, 2026 tools list, and signal trapping concepts in **[docs/SIGNALS.md](docs/SIGNALS.md)**. This is the heart of the 2026 platform.

### Work on a real protocol

```bash
mkdir -p workspace/my-audit/contracts
# copy or git clone your private target here (never push it)
make lint TARGET=workspace/my-audit
```

### Practice exploits

```bash
cd workspace/damn-vulnerable-defi
forge install
forge test
# then break levels one by one
```

### Update everything to bleeding edge (submodules)

```bash
make update-tools
```

Review the diff, commit the new pinned SHAs when you are happy.

---

## Configuration

All engines read from `config/`:

- `slither.config.json` — detector selection, remappings, filters
- `aderyn.config.toml` — depth, excludes, output format
- `.solhint.json` — rules tuned for real audits (not tutorial strictness)

Edit once, benefit everywhere.

---

## Philosophy & Design Principles

1. **Everything local & sovereign** — no contract source ever touches a third-party SaaS. All AI reasoning runs through your own OpenFang + vLLM stack (🧠).
2. **Reproducible** — submodules + pinned versions + declarative configs.
3. **Composable** — classical tools + `lint_all.py` + `audit_fang.py` + Makefile feel like one unified platform.
4. **Dynamic & fast on re-runs** — second and subsequent `./setup.sh` or `make setup` are near-instant (smart guards everywhere).
5. **Zero-day signal hunting ready** — see [docs/SIGNALS.md](docs/SIGNALS.md) for the full 2026 exploitation matrix, cost/risk table, and trapping pipeline vision.
6. **Arch-native but not Arch-only** — pacman is first-class; Debian/Ubuntu paths exist for convenience.

---

### Verify & doctor

```bash
make doctor          # environment health check: forge, slither, aderyn, docker, venv
make verify          # max-level workspace verification (scripts/verify.sh)
make verify STRICT=1 # strict mode
./setup.sh --verify  # run setup, then strict verification
```

## Troubleshooting

| Symptom                    | Fix |
|---------------------------|-----|
| `docker: permission denied` | `sudo usermod -aG docker $USER` then re-login |
| `forge: command not found` | Run `foundryup` manually or re-run `make setup` |
| Submodules empty after clone | `git submodule update --init --recursive` |
| Python packages fail on Arch | Make sure `python-virtualenv` and base-devel are present |
| Want to nuke everything generated | `make clean` (does not touch submodules or venv) |

---

## Extending

- Add a new static tool → drop a runner in `bin/lint_all.py` + config if needed
- Add a new submodule → `git submodule add <url> tools/newthing`
- New practice target → add another entry under `workspace/`
- CI for your own audits → copy the pattern from `Makefile` into your own repo's GitHub Actions

---

## Acknowledgments

This workspace stands on the shoulders of:

- [Trail of Bits](https://github.com/crytic) — Slither, Echidna, Mythril
- [Cyfrin](https://github.com/Cyfrin) — Aderyn
- [OpenZeppelin](https://github.com/OpenZeppelin) — Damn Vulnerable DeFi (educational masterpiece)
- [Alt-Research](https://github.com/alt-research) — SolidityGuard
- All the individual researchers behind Krait, RugProof, honeypotscan, Medusa, Solhint, and the many other tools in this stack (plus the OpenFang project itself for the sovereign agent layer) (solql upstream was unavailable at assembly time)

Special thanks to the Arch Linux security community and everyone building local-first tooling in 2025–2026.

---

## License

MIT © 2026 toxicwind

---

<p align="center">
  <strong>Build sovereign. Audit privately. Ship with confidence.</strong>
</p>

## Sovereign Secrets & MCP Stack

This repo is public, so the secrets discipline is described here in general
terms only. Specific key names, values, prefixes, and machine-local secret
paths do not belong in this README — or any commit.

- One consolidated secrets store on the machine running the stack (mode 0600),
  read by the workspace at runtime. Never committed, never pasted into docs,
  issues, or chat.
- Keys are grouped by family (messaging, mesh, context providers, LLM /
  search / TTS) and consumed from that store by OpenFang agents and MCP
  integrations — `openfang agent list` / `openfang mcp` shows what is wired.
- Canonical local services: OpenFang (14720), vLLM (14718), Caddy landing
  (14719). Keep experimental or red-herring services out of this set.
- Autonomous agents run on cron/triggers via OpenFang (e.g. diagnostic log
  scans).
- Anything that ever touched a public surface gets rotated. No exceptions.
