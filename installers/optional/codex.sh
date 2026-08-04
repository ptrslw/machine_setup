#!/usr/bin/env bash
# installers/optional/codex.sh — OpenAI Codex CLI (exploratory agent pathway).
#
# Opt-in only. Never run by `bootstrap.sh all`.
#   ./bootstrap.sh codex
#
# Config: ~/.codex/config.toml (linked from home/.codex/config.toml).
# See docs/agents.md.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../lib/common.sh
source "$SCRIPT_DIR/../../lib/common.sh"

header "OpenAI Codex CLI"
already_installed codex

if [[ "${DRY_RUN:-false}" == "true" ]]; then
    info "[DRY RUN] would install Codex CLI via npm (@openai/codex)"
    exit 0
fi

if [[ "$OS" == "macos" ]] && is_cmd brew; then
    # Cask when available; fall back to npm.
    if brew info --cask codex &>/dev/null; then
        brew install --cask codex
    elif is_cmd npm; then
        npm install -g @openai/codex
    else
        error "Need Homebrew cask 'codex' or npm. Run ./bootstrap.sh packages first."
        exit 1
    fi
elif is_cmd npm; then
    npm install -g @openai/codex
else
    error "npm not found. Run ./bootstrap.sh packages first."
    exit 1
fi

success "Codex installed ($(codex --version 2>/dev/null | head -1 || echo installed))"
info "Config: ~/.codex/config.toml — DeepSeek / Ollama providers. See docs/agents.md."
