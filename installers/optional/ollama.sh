#!/usr/bin/env bash
# installers/optional/ollama.sh — Ollama local model runtime (for Codex / OpenCode).
#
# Opt-in only. Never run by `bootstrap.sh all`.
#   ./bootstrap.sh ollama
#
# Installs the daemon only. Pull models yourself, e.g.:
#   ollama pull qwen2.5-coder
# See docs/agents.md.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../lib/common.sh
source "$SCRIPT_DIR/../../lib/common.sh"

header "Ollama"
already_installed ollama

if [[ "${DRY_RUN:-false}" == "true" ]]; then
    info "[DRY RUN] would install Ollama (brew cask on macOS, install.sh on Linux)"
    exit 0
fi

if [[ "$OS" == "macos" ]]; then
    require_brew
    brew install --cask ollama
elif [[ "$OS" == "ubuntu" ]]; then
    curl -fsSL https://ollama.com/install.sh | sh
else
    error "Unsupported OS: $OS"
    exit 1
fi

success "Ollama installed ($(ollama --version 2>/dev/null | head -1 || echo installed))"
info "Start the app/daemon, then: ollama pull qwen2.5-coder"
info "Point Codex (codex --oss) or OpenCode at localhost:11434 — see docs/agents.md."
