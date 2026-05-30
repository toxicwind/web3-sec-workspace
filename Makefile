# Makefile — Fluid developer experience for web3-sec-workspace (2026)
# Usage: make help | make setup | make lint TARGET=workspace/...

SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c

WORKSPACE_ROOT := $(shell pwd)
VENV := $(WORKSPACE_ROOT)/venv
PYTHON := $(VENV)/bin/python
LINT_SCRIPT := $(WORKSPACE_ROOT)/bin/lint_all.py

# Colors
CYAN  := \033[0;36m
GREEN := \033[0;32m
YELLOW:= \033[1;33m
NC    := \033[0m

.PHONY: help setup start lint audit clean submodules update-tools doctor

help:
	@echo -e "$(CYAN)web3-sec-workspace — Sovereign Audit Lab (2026)$(NC)"
	@echo
	@echo "  $(GREEN)make setup$(NC)           Run full modular bootstrap (idempotent)"
	@echo "  $(GREEN)make start$(NC)           Drop into activated environment shell"
	@echo "  $(GREEN)make lint TARGET=dir$(NC) Run all static analyzers on target"
	@echo "  $(GREEN)make audit TARGET=dir$(NC) Alias for lint"
	@echo "  $(GREEN)make submodules$(NC)      Re-init / update all git submodules"
	@echo "  $(GREEN)make update-tools$(NC)    Pull latest commits for all submodules"
	@echo "  $(GREEN)make doctor$(NC)          Quick environment health check"
	@echo "  $(GREEN)make clean$(NC)           Remove reports, logs, venv (keeps source)"
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
		echo -e "$(YELLOW)Usage: make lint TARGET=path/to/solidity/project$(NC)"; \
		exit 1; \
	fi
	@$(PYTHON) $(LINT_SCRIPT) $(TARGET) || true

submodules:
	@git submodule update --init --recursive --depth 1 --jobs 4
	@bash scripts/setup-node-tools.sh || true
	@echo -e "$(GREEN)Submodules ready$(NC)"

update-tools:
	@echo -e "$(CYAN)Updating all tool submodules to latest...$(NC)"
	@git submodule update --remote --merge
	@git submodule foreach 'git checkout main || git checkout master || true'
	@echo -e "$(GREEN)Done. Review changes with 'git status'$(NC)"

doctor:
	@echo -e "$(CYAN)Environment doctor...$(NC)"
	@command -v forge   && echo "  forge:   $$(forge --version 2>/dev/null | head -1)"   || echo "  forge:   MISSING"
	@command -v slither && echo "  slither: $$(slither --version 2>/dev/null || echo '?')" || echo "  slither: MISSING"
	@command -v aderyn  && echo "  aderyn:  present" || echo "  aderyn:  MISSING (cargo install)"
	@command -v docker  && docker images | grep -q solidityguard && echo "  solidityguard: pulled" || echo "  solidityguard: not pulled"
	@[ -d venv ] && echo "  venv:    present" || echo "  venv:    MISSING (run make setup)"
	@echo -e "$(GREEN)Doctor complete$(NC)"

clean:
	@rm -rf reports/* logs/* 2>/dev/null || true
	@echo "Cleaned reports and logs (venv preserved)"
