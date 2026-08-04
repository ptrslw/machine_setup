#!/usr/bin/env bash
# installers/optional/opencode.sh — OpenCode CLI (exploratory agent pathway).
#
# Opt-in only. Never run by `bootstrap.sh all`.
#   ./bootstrap.sh opencode
#
# Config: ~/.config/opencode/opencode.json (linked from home/).
# See docs/agents.md.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../lib/common.sh
source "$SCRIPT_DIR/../../lib/common.sh"

header "OpenCode"
already_installed opencode

if [[ "${DRY_RUN:-false}" == "true" ]]; then
    info "[DRY RUN] would install OpenCode (brew tap or npm opencode-ai)"
    exit 0
fi

if [[ "$OS" == "macos" ]] && is_cmd brew; then
    brew install anomalyco/tap/opencode || brew install opencode
elif is_cmd npm; then
    npm install -g opencode-ai@latest
else
    error "Need Homebrew or npm. Run ./bootstrap.sh packages first."
    exit 1
fi

success "OpenCode installed ($(opencode --version 2>/dev/null | head -1 || echo installed))"
info "Config: ~/.config/opencode/opencode.json — DeepSeek / Ollama providers. See docs/agents.md."
