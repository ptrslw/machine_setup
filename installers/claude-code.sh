#!/usr/bin/env bash
# installers/claude-code.sh — Claude Code CLI via npm.
# Requires Node (run installers/node.sh / `bootstrap.sh packages` first).
# Invoked by `bootstrap.sh claude`, not by the generic packages installer loop.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

header "Claude Code"
already_installed claude

if ! is_cmd npm; then
    error "npm not found. Run installers/node.sh first."
    exit 1
fi

if [[ "${DRY_RUN:-false}" == "true" ]]; then
    info "[DRY RUN] would run: npm install -g @anthropic-ai/claude-code"
    exit 0
fi

npm install -g @anthropic-ai/claude-code
success "Claude Code installed ($(claude --version 2>/dev/null || echo installed))"
