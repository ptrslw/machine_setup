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

# --- Agent skill packs (packages/agent-skills.txt) ------------------------
# Lines are owner/repo@sha (full 40-char hex). Skill packs steer agents that
# run shell and edit trees — never float on main.

# Strip comments/whitespace from a manifest line. Empty → return 1.
agent_skill_strip_line() {
    local line="${1%%#*}"
    # trim leading/trailing IFS whitespace
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [[ -n "$line" ]] || return 1
    printf '%s\n' "$line"
}

# Parse owner/repo@sha into REPO and SHA (namerefs via globals for POSIX bash 4+).
# Usage: agent_skill_parse_entry "$line" && echo "$AGENT_SKILL_REPO @$AGENT_SKILL_SHA"
agent_skill_parse_entry() {
    local raw="$1" entry repo sha
    AGENT_SKILL_REPO=""
    AGENT_SKILL_SHA=""
    entry="$(agent_skill_strip_line "$raw")" || return 1

    case "$entry" in
        */*@*)
            repo="${entry%@*}"
            sha="${entry##*@}"
            ;;
        *)
            error "agent-skills: expected owner/repo@sha, got: $entry"
            return 2
            ;;
    esac

    case "$repo" in
        */*) ;;
        *)
            error "agent-skills: invalid repo (want owner/name): $repo"
            return 2
            ;;
    esac
    # Reject path traversal / extra slashes.
    case "$repo" in
        */*/*|.*|*..*)
            error "agent-skills: invalid repo: $repo"
            return 2
            ;;
    esac
    if [[ ! "$sha" =~ ^[0-9a-fA-F]{40}$ ]]; then
        error "agent-skills: pin must be a full 40-char hex SHA (got: $sha)"
        return 2
    fi

    # Exported for callers (installers/agent-skills.sh, bootstrap doctor).
    # shellcheck disable=SC2034
    AGENT_SKILL_REPO="$repo"
    # shellcheck disable=SC2034
    AGENT_SKILL_SHA="$(printf '%s' "$sha" | tr 'A-F' 'a-f')"
    return 0
}

agent_skill_cache_path() {
    local repo="$1"
    local root="${2:-${AGENT_SKILLS_CACHE:-$HOME/.cache/agent-skills}}"
    printf '%s/%s\n' "$root" "${repo//\//__}"
}

# Detached shallow fetch of a pinned SHA into $1 (dest dir). $2=owner/repo $3=sha.
agent_skill_ensure_cache() {
    local dest="$1" repo="$2" sha="$3"
    local url="https://github.com/${repo}.git"
    local head=""

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        info "[DRY RUN] would pin $repo@$sha in $dest"
        return 0
    fi
    if ! is_cmd git; then
        error "git not found — cannot cache $repo"
        return 1
    fi

    if [[ -d "$dest/.git" ]]; then
        head="$(git -C "$dest" rev-parse HEAD 2>/dev/null || true)"
        if [[ "$head" == "$sha" ]]; then
            success "cache at pin: $dest ($sha)"
            return 0
        fi
        info "cache: moving $dest from ${head:-unknown} → $sha"
        if ! GIT_TERMINAL_PROMPT=0 git -C "$dest" fetch --depth 1 origin "$sha"; then
            error "cache: cannot fetch $sha from $url"
            return 1
        fi
        if ! git -C "$dest" checkout --detach --quiet FETCH_HEAD; then
            error "cache: cannot checkout $sha in $dest"
            return 1
        fi
    else
        mkdir -p "$dest"
        git -C "$dest" init --quiet
        git -C "$dest" remote add origin "$url"
        # GIT_TERMINAL_PROMPT=0: never block provisioning on a credential prompt.
        if ! GIT_TERMINAL_PROMPT=0 git -C "$dest" fetch --depth 1 origin "$sha"; then
            error "cache: cannot fetch $sha from $url"
            rm -rf "$dest"
            return 1
        fi
        if ! git -C "$dest" checkout --detach --quiet FETCH_HEAD; then
            error "cache: cannot checkout $sha in $dest"
            rm -rf "$dest"
            return 1
        fi
    fi

    head="$(git -C "$dest" rev-parse HEAD)"
    if [[ "$head" != "$sha" ]]; then
        error "cache: expected $sha, got $head"
        return 1
    fi
    success "cache at pin: $dest ($sha)"
}

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
