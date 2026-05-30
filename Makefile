# Makefile — Fluid developer experience for web3-sec-workspace (2026)
# Usage: make help | make setup | make lint TARGET=workspace/...

SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c

WORKSPACE_ROOT := $(shell pwd)
VENV := $(WORKSPACE_ROOT)/venv
PYTHON := $(VENV)/bin/python
LINT_SCRIPT := $(WORKSPACE_ROOT)/bin/lint_all.py

.PHONY: help setup start lint audit clean submodules update-tools doctor verify test

help:
	@echo -e "\033[0;36mweb3-sec-workspace — Sovereign Audit Lab (2026)\033[0m"
	@echo
	@echo "  \033[0;32mmake setup\033[0m           Run full modular bootstrap (idempotent)"
	@echo "  \033[0;32mmake start\033[0m           Drop into activated environment shell"
	@echo "  \033[0;32mmake lint TARGET=dir\033[0m Run all static analyzers on target"
	@echo "  \033[0;32mmake audit TARGET=dir\033[0m Alias for lint"
	@echo "  \033[0;32mmake fang TARGET=dir\033[0m  Sovereign AI audit via local OpenFang + vLLM (AGENT=...)"
	@echo "  \033[0;32mmake submodules\033[0m      Re-init / update all git submodules"
	@echo "  \033[0;32mmake update-tools\033[0m    Pull latest commits for all submodules"
	@echo "  \033[0;32mmake doctor\033[0m          Quick environment health check"
	@echo "  \033[0;32mmake clean\033[0m           Remove reports, logs, venv (keeps source)"
	@echo
	@echo "Examples:"
	@echo "  make lint TARGET=workspace/damn-vulnerable-defi"
	@echo "  make audit TARGET=examples/my-protocol"
	@echo

setup:
	@./setup.sh

start:
	@./start.sh

lint audit:
	@if [ -z "$(TARGET)" ]; then \
		echo -e "\033[1;33mUsage: make lint TARGET=path/to/solidity/project\033[0m"; \
		exit 1; \
	fi
	@$(PYTHON) $(LINT_SCRIPT) $(TARGET) || true

fang ai-audit:
	@if [ -z "$(TARGET)" ]; then \
		echo -e "\033[1;33mUsage: make fang TARGET=path/to/solidity/project [AGENT=security-auditor]\033[0m"; \
		exit 1; \
	fi
	@$(PYTHON) $(WORKSPACE_ROOT)/bin/audit_fang.py $(TARGET) --agent $${AGENT:-security-auditor} || true

submodules:
	@git submodule update --init --recursive --depth 1 --jobs 4
	@bash scripts/setup-node-tools.sh || true
	@echo -e "\033[0;32mSubmodules ready\033[0m"

update-tools:
	@echo -e "\033[0;36mUpdating all tool submodules to latest...\033[0m"
	@git submodule update --remote --merge
	@git submodule foreach 'git checkout main || git checkout master || true'
	@echo -e "\033[0;32mDone. Review changes with 'git status'\033[0m"

doctor:
	@echo -e "\033[0;36mEnvironment doctor...\033[0m"
	@command -v forge   && echo "  forge:   $$(forge --version 2>/dev/null | head -1)"   || echo "  forge:   MISSING"
	@command -v slither && echo "  slither: $$(slither --version 2>/dev/null || echo '?')" || echo "  slither: MISSING"
	@command -v aderyn  && echo "  aderyn:  present" || echo "  aderyn:  MISSING (cargo install)"
	@command -v docker  && docker images | grep -q solidityguard && echo "  solidityguard: pulled" || echo "  solidityguard: not pulled"
	@[ -d venv ] && echo "  venv:    present" || echo "  venv:    MISSING (run make setup)"
	@echo -e "\033[0;32mDoctor complete\033[0m"

clean:
	@rm -rf reports/* logs/* 2>/dev/null || true
	@echo "Cleaned reports and logs (venv preserved)"

verify test:
	@./scripts/verify.sh $(if $(STRICT),--strict,)
	@echo
	@echo "Run 'make verify STRICT=1' for stricter checking"
