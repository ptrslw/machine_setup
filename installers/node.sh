#!/usr/bin/env bash
# installers/node.sh — install Node.js. Required by claude-code.sh (npm).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

header "Node.js"
already_installed node

if [[ "${DRY_RUN:-false}" == "true" ]]; then
    info "[DRY RUN] would install Node.js via ${OS}'s package manager"
    exit 0
fi

if [[ "$OS" == "macos" ]]; then
    require_brew
    brew install node
elif [[ "$OS" == "ubuntu" ]]; then
    # NodeSource LTS repo — distro packages are often too old for Claude Code.
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt-get install -y nodejs
else
    error "Unsupported OS: $OS"
    exit 1
fi

success "Node.js installed ($(node --version))"
