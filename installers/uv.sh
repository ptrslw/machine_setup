#!/usr/bin/env bash
# installers/uv.sh — install uv (Python version + venv manager). Idempotent:
# exits early if `uv` is already on PATH.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

header "uv"
already_installed uv

if [[ "${DRY_RUN:-false}" == "true" ]]; then
    info "[DRY RUN] would run: curl -LsSf https://astral.sh/uv/install.sh | sh"
    exit 0
fi

curl -LsSf https://astral.sh/uv/install.sh | sh
# Official installer places the binary in ~/.local/bin (already on PATH via
# .zprofile / .profile). Export here so the next line works in this script.
export PATH="$HOME/.local/bin:$PATH"

uv python install 3.12
success "uv installed ($(uv --version))"
