#!/usr/bin/env bash
# installers/docker.sh — Docker Engine (Ubuntu) or skip when Brewfile already
# installed docker + Colima (macOS). Idempotent.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

header "Docker"

if [[ "$OS" == "macos" ]]; then
    if is_cmd docker; then
        success "Docker already installed ($(command -v docker))"
        exit 0
    fi
    warn "Docker not on PATH — install via Brewfile (colima + docker) with ./bootstrap.sh packages"
    exit 0
fi

require_ubuntu
already_installed docker

if [[ "${DRY_RUN:-false}" == "true" ]]; then
    info "[DRY RUN] would install Docker Engine from Docker's apt repository"
    exit 0
fi

# Official Docker apt repository (Ubuntu).
sudo apt-get install -y --no-install-recommends ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
if [[ ! -f /etc/apt/keyrings/docker.asc ]]; then
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
fi

# shellcheck disable=SC1091
. /etc/os-release
ARCH="$(dpkg --print-architecture)"
echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -qq
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

if ! getent group docker >/dev/null; then
    sudo groupadd docker
fi
sudo usermod -aG docker "$USER" || true
warn "Log out and back in (or newgrp docker) so group membership applies."

success "Docker installed ($(docker --version 2>/dev/null | head -1 || echo installed))"
