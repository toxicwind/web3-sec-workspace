#!/bin/bash
# lib.sh — Shared utilities for web3-sec-workspace modular setup
# 2026 sovereign edition: clean logging, distro awareness, idempotent helpers

set -euo pipefail

# --- Colors (2026 terminal aesthetics) ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# --- Logging ---
log_info()    { echo -e "${CYAN}[*]${NC} $1"; }
log_success() { echo -e "${GREEN}[✔]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
log_error()   { echo -e "${RED}[✖]${NC} $1" >&2; }
log_step()    { echo -e "\n${BOLD}${MAGENTA}▶ $1${NC}"; }
log_dim()     { echo -e "${DIM}$1${NC}"; }

# --- Checks ---
command_exists() {
  command -v "$1" &>/dev/null
}

require_cmd() {
  if ! command_exists "$1"; then
    log_error "Missing required command: $1"
    return 1
  fi
}

# --- Distro detection (extendable) ---
detect_distro() {
  if [ -f /etc/arch-release ] || [ -f /etc/manjaro-release ]; then
    echo "arch"
  elif [ -f /etc/debian_version ]; then
    echo "debian"
  elif [ -f /etc/redhat-release ] || [ -f /etc/fedora-release ]; then
    echo "rhel"
  else
    echo "unknown"
  fi
}

# --- Idempotent package install (Arch-first, graceful others) ---
install_pkg() {
  local pkg="$1"
  local distro
  distro=$(detect_distro)

  case "$distro" in
    arch)
      if ! pacman -Qi "$pkg" &>/dev/null; then
        log_info "Installing $pkg (pacman)..."
        sudo pacman -S --noconfirm "$pkg"
      else
        log_dim "  $pkg already installed"
      fi
      ;;
    debian)
      log_warn "Debian/Ubuntu detected — using apt (best effort)"
      sudo apt-get update -qq && sudo apt-get install -y "$pkg" 2>/dev/null || log_warn "Could not install $pkg via apt"
      ;;
    *)
      log_warn "Unknown distro. Please install $pkg manually."
      ;;
  esac
}

# --- Safe git shallow clone helper (for non-submodule cases) ---
safe_git_clone() {
  local url="$1" dir="$2" depth="${3:-1}"
  if [ -d "$dir/.git" ]; then
    log_dim "  Submodule or clone already present at $dir"
    return 0
  fi
  log_info "Cloning $url → $dir"
  git clone --depth "$depth" "$url" "$dir"
}

# --- Banner ---
print_banner() {
  cat << 'EOF'
   __        __   _     _____   ____     ____            __        __         _     _                 
   \ \      / /__| |__ |___ /  / ___|___/ ___|  ___  ___ \ \      / /__  _ __| | __| | ___  _ __  ___ 
    \ \ /\ / / _ \ '_ \  |_ \  \___ \ _ \___ \ / _ \/ __| \ \ /\ / / _ \| '__| |/ _` |/ _ \| '_ \/ __|
     \ V  V /  __/ |_) |___) |  ___) | | |__) |  __/ (__   \ V  V / (_) | |  | | (_| | (_) | | | \__ \
      \_/\_/ \___|_.__/|____/  |____/| |____/ \___|\___|   \_/\_/ \___/|_|  |_|\__,_|\___/|_| |_|___/
                                                                                                    
   Sovereign Web3 Security Audit Workspace • 2026
EOF
}
