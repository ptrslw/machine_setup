#!/usr/bin/env bash
# lib/common.sh — helpers for bootstrap.sh and installers/*.sh.
# Source this file; do not execute it directly.

# Terminal colors (ANSI). NC = "no color" reset.
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
# shellcheck disable=SC2034  # consumed by bootstrap.sh, which sources this file
DIM='\033[2m'
NC='\033[0m'

info()    { echo -e "  ${CYAN}→${NC} $*"; }
success() { echo -e "  ${GREEN}✓${NC} $*"; }
warn()    { echo -e "  ${YELLOW}⚠${NC} $*"; }
error()   { echo -e "  ${RED}✗${NC} $*" >&2; }
header()  { echo -e "\n${BOLD}▸ $*${NC}"; }

is_cmd() { command -v "$1" >/dev/null 2>&1; }

# Exit successfully if $1 is already on PATH (idempotent installers).
already_installed() {
    local cmd="$1" label="${2:-$1}"
    if is_cmd "$cmd"; then
        success "$label already installed ($(command -v "$cmd"))"
        exit 0
    fi
}

require_ubuntu() {
    if [[ "${OS:-}" != "ubuntu" ]]; then
        warn "Skipping — Ubuntu required (current: ${OS:-unknown})"
        exit 0
    fi
}

require_macos() {
    if [[ "${OS:-}" != "macos" ]]; then
        warn "Skipping — macOS required (current: ${OS:-unknown})"
        exit 0
    fi
}

require_brew() {
    if ! is_cmd brew; then
        error "Homebrew is required. Install it first (bootstrap.sh packages does this on macOS)."
        exit 1
    fi
}

# NVIDIA GPU present and nvidia-smi works (used by Isaac Sim installer).
require_nvidia() {
    if [[ "${HAS_NVIDIA:-false}" != "true" ]]; then
        error "NVIDIA GPU required (nvidia-smi not available)."
        exit 1
    fi
}

# --- System detection (exported once for callers) -------------------------

detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ -f /etc/os-release ]] && grep -qi 'ubuntu' /etc/os-release; then
        echo "ubuntu"
    else
        echo "linux"
    fi
}

detect_arch() {
    case "$(uname -m)" in
        x86_64)        echo "x86_64" ;;
        aarch64|arm64) echo "arm64" ;;
        *)             uname -m ;;
    esac
}

detect_ubuntu_version() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        echo "${VERSION_ID:-}"
    fi
}

detect_nvidia() {
    if is_cmd nvidia-smi && nvidia-smi &>/dev/null; then
        echo "true"
    else
        echo "false"
    fi
}

export OS="${OS:-$(detect_os)}"
export ARCH="${ARCH:-$(detect_arch)}"
export UBUNTU_VERSION="${UBUNTU_VERSION:-$(detect_ubuntu_version)}"
export HAS_NVIDIA="${HAS_NVIDIA:-$(detect_nvidia)}"

# --- Symlinking -----------------------------------------------------------
# Core primitive for `bootstrap.sh link`:
#   - if $dest already points at $src → no-op
#   - if $dest exists as a real file/dir → move it under ~/.dotfiles-backup/<ts>/
#   - then ln -s $src $dest
# Honors DRY_RUN. Backups may contain old secrets — .gitignore excludes them.

BACKUP_ROOT="${BACKUP_ROOT:-$HOME/.dotfiles-backup/$(date +%Y%m%d_%H%M%S)}"

symlink_with_backup() {
    local src="$1" dest="$2"

    if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
        success "$dest already linked"
        return 0
    fi

    if [[ -e "$dest" || -L "$dest" ]]; then
        if [[ "${DRY_RUN:-false}" == "true" ]]; then
            info "[DRY RUN] would back up $dest -> $BACKUP_ROOT/"
        else
            mkdir -p "$BACKUP_ROOT"
            local rel="${dest#"$HOME"/}"
            mkdir -p "$BACKUP_ROOT/$(dirname "$rel")"
            mv "$dest" "$BACKUP_ROOT/$rel"
            warn "backed up existing $dest -> $BACKUP_ROOT/$rel"
        fi
    fi

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        info "[DRY RUN] would link $dest -> $src"
    else
        mkdir -p "$(dirname "$dest")"
        ln -s "$src" "$dest"
        success "linked $dest -> $src"
    fi
}
