#!/usr/bin/env bash
# installers/optional/isaac-sim.sh — NVIDIA Isaac Sim via Omniverse Launcher.
#
# Opt-in only. Never run by `bootstrap.sh all`.
#   ./bootstrap.sh isaac
#
# Isaac install requires a GUI login to an NVIDIA account — this script checks
# prerequisites and prints the steps.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../lib/common.sh
source "$SCRIPT_DIR/../../lib/common.sh"

header "NVIDIA Isaac Sim"
require_ubuntu
require_nvidia

if [[ -d "$HOME/.local/share/ov/pkg" ]]; then
    success "NVIDIA Omniverse already present under ~/.local/share/ov/pkg"
    info "Use the Omniverse Launcher to install or update Isaac Sim."
    exit 0
fi

if [[ "${DRY_RUN:-false}" == "true" ]]; then
    info "[DRY RUN] would verify CUDA/driver and print Omniverse Launcher install steps"
    exit 0
fi

if ! is_cmd nvcc; then
    error "CUDA Toolkit not found (nvcc missing)."
    info "Install CUDA 12.x before Isaac Sim, then re-run ./bootstrap.sh isaac"
    exit 1
fi

DRIVER_VERSION=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -1)
DRIVER_MAJOR=$(echo "$DRIVER_VERSION" | cut -d. -f1)
if [[ -z "$DRIVER_MAJOR" ]] || (( DRIVER_MAJOR < 535 )); then
    error "Isaac Sim requires NVIDIA driver 535+. Current: ${DRIVER_VERSION:-unknown}"
    info "Update via: sudo ubuntu-drivers install"
    exit 1
fi

info "Isaac Sim is installed via the NVIDIA Omniverse Launcher (GUI + NVIDIA account)."
info ""
info "Steps:"
info "  1. Download the Omniverse Launcher AppImage:"
echo "       https://install.launcher.omniverse.nvidia.com/omniverse-launcher-linux.AppImage"
info "  2. Make it executable and run it:"
echo "       chmod +x omniverse-launcher-linux.AppImage"
echo "       ./omniverse-launcher-linux.AppImage"
info "  3. Sign in with your NVIDIA Developer account."
info "  4. Exchange → search 'Isaac Sim' → Install."
info ""
info "Download page: https://www.nvidia.com/en-us/omniverse/download/"
warn "Automatic installation is not supported — the Launcher needs a GUI login."

exit 0
