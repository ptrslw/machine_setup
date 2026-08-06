#!/usr/bin/env bash
# installers/wezterm.sh — WezTerm stable on Ubuntu. On macOS the Brewfile cask
# handles it (bootstrap removes wezterm@nightly first if present).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

header "WezTerm"

if [[ "$OS" == "macos" ]]; then
    if is_cmd wezterm; then
        success "WezTerm already installed ($(command -v wezterm))"
        exit 0
    fi
    info "On macOS, WezTerm comes from the Brewfile (./bootstrap.sh packages)"
    exit 0
fi

require_ubuntu
already_installed wezterm

if [[ "${DRY_RUN:-false}" == "true" ]]; then
    info "[DRY RUN] would install WezTerm (stable) from the WezTerm apt repository"
    exit 0
fi

# Stable and nightly .debs conflict — keep only stable.
if dpkg -l wezterm-nightly 2>/dev/null | grep -q '^ii'; then
    info "Removing wezterm-nightly (conflicts with stable wezterm)"
    sudo DEBIAN_FRONTEND=noninteractive apt-get remove -y wezterm-nightly
fi

curl -fsSL https://apt.fury.io/wez/gpg.key \
    | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg
echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' \
    | sudo tee /etc/apt/sources.list.d/wezterm.list > /dev/null
sudo apt-get update -qq
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y wezterm

success "WezTerm installed ($(wezterm --version 2>/dev/null | head -1 || echo installed))"
