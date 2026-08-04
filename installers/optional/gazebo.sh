#!/usr/bin/env bash
# installers/optional/gazebo.sh — Gazebo Harmonic (LTS) + ROS 2 bridge packages.
#
# Opt-in only. Never run by `bootstrap.sh all`.
#   ./bootstrap.sh gazebo
#   ROS_DISTRO=jazzy GZ_DISTRO=harmonic ./bootstrap.sh gazebo
#
# Expects ROS 2 already installed (./bootstrap.sh ros2).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../lib/common.sh
source "$SCRIPT_DIR/../../lib/common.sh"

header "Gazebo Harmonic + ROS 2 bridge"
require_ubuntu

ROS_DISTRO="${ROS_DISTRO:-jazzy}"
GZ_DISTRO="${GZ_DISTRO:-harmonic}"
OSRF_KEYRING="/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg"
OSRF_LIST="/etc/apt/sources.list.d/gazebo-stable.list"

if [[ ! -d "/opt/ros/${ROS_DISTRO}" ]]; then
    error "ROS 2 ${ROS_DISTRO} not found. Run: ./bootstrap.sh ros2"
    exit 1
fi

if is_cmd gz; then
    GZ_VER="$(gz sim --version 2>/dev/null | grep -oE '[0-9]+\.[0-9.]+' | head -1 || echo 'unknown')"
    success "Gazebo already installed (gz-sim ${GZ_VER})"
    exit 0
fi

if [[ "${DRY_RUN:-false}" == "true" ]]; then
    info "[DRY RUN] would install gz-${GZ_DISTRO} and ros-${ROS_DISTRO}-ros-gz* bridge packages"
    exit 0
fi

info "Adding OSRF apt repository for Gazebo…"
sudo apt-get install -y --no-install-recommends curl lsb-release gnupg

if [[ ! -f "$OSRF_KEYRING" ]]; then
    info "Installing OSRF keyring…"
    sudo curl -fsSL https://packages.osrfoundation.org/gazebo.gpg \
        -o "$OSRF_KEYRING"
fi

ARCH="$(dpkg --print-architecture)"
CODENAME="$(lsb_release -cs)"
REPO_LINE="deb [arch=${ARCH} signed-by=${OSRF_KEYRING}] http://packages.osrfoundation.org/gazebo/ubuntu-stable ${CODENAME} main"

if [[ ! -f "$OSRF_LIST" ]] || ! grep -Fqs -- "$REPO_LINE" "$OSRF_LIST"; then
    info "Writing OSRF source list…"
    printf '%s\n' "$REPO_LINE" | sudo tee "$OSRF_LIST" > /dev/null
fi

sudo apt-get update -qq

info "Installing gz-${GZ_DISTRO} and ROS↔Gazebo bridge packages…"
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    "gz-${GZ_DISTRO}" \
    "ros-${ROS_DISTRO}-ros-gz" \
    "ros-${ROS_DISTRO}-ros-gz-sim" \
    "ros-${ROS_DISTRO}-ros-gz-bridge" \
    "ros-${ROS_DISTRO}-gz-tools-vendor" \
    "ros-${ROS_DISTRO}-gz-sim-vendor" \
    "ros-${ROS_DISTRO}-gz-ros2-control" \
    "ros-${ROS_DISTRO}-gz-ros2-control-demos" \
    "libgz-gui8-dev"

success "Gazebo ${GZ_DISTRO} + ROS 2 bridge installed"
