#!/usr/bin/env bash
# installers/optional/ros2.sh — ROS 2 Jazzy (LTS) on Ubuntu 24.04.
#
# Opt-in only. Never run by `bootstrap.sh all`.
#   ./bootstrap.sh ros2
#   ROS_DISTRO=jazzy ./bootstrap.sh ros2
#
# Does NOT append to ~/.bashrc — activate with `ros2-env` (see docs/robotics.md).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../lib/common.sh
source "$SCRIPT_DIR/../../lib/common.sh"

header "ROS 2"
require_ubuntu

ROS_DISTRO="${ROS_DISTRO:-jazzy}"
ROS_KEYRING="/usr/share/keyrings/ros-archive-keyring.gpg"
ROS_LIST="/etc/apt/sources.list.d/ros2.list"

if [[ "${UBUNTU_VERSION:-}" != "24.04" ]]; then
    error "ROS 2 ${ROS_DISTRO} requires Ubuntu 24.04 (detected: ${UBUNTU_VERSION:-unknown})"
    exit 1
fi

if [[ -d "/opt/ros/${ROS_DISTRO}" ]]; then
    success "ROS 2 ${ROS_DISTRO} already installed (/opt/ros/${ROS_DISTRO})"
    info "Activate in this shell: ros2-env ${ROS_DISTRO}"
    exit 0
fi

if [[ "${DRY_RUN:-false}" == "true" ]]; then
    info "[DRY RUN] would install ROS 2 ${ROS_DISTRO} desktop + common robotics packages"
    exit 0
fi

info "Configuring locale (en_US.UTF-8)…"
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends locales
sudo locale-gen en_US en_US.UTF-8
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

info "Enabling universe repository…"
sudo apt-get install -y --no-install-recommends software-properties-common curl
sudo add-apt-repository -y universe
sudo apt-get update -qq

if [[ ! -f "$ROS_KEYRING" ]]; then
    info "Installing ROS 2 apt keyring…"
    sudo curl -fsSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
        -o "$ROS_KEYRING"
fi

ARCH="$(dpkg --print-architecture)"
# shellcheck disable=SC1091
CODENAME="$(. /etc/os-release && echo "${UBUNTU_CODENAME}")"
REPO_LINE="deb [arch=${ARCH} signed-by=${ROS_KEYRING}] http://packages.ros.org/ros2/ubuntu ${CODENAME} main"

if [[ ! -f "$ROS_LIST" ]] || ! grep -Fqs -- "$REPO_LINE" "$ROS_LIST"; then
    info "Adding ROS 2 apt source list…"
    printf '%s\n' "$REPO_LINE" | sudo tee "$ROS_LIST" > /dev/null
fi

sudo apt-get update -qq
info "Upgrading base packages before ROS 2 install…"
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

info "Installing ROS 2 ${ROS_DISTRO} desktop + dev tools…"
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    "ros-${ROS_DISTRO}-desktop" \
    ros-dev-tools

info "Installing common robotics packages…"
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    "ros-${ROS_DISTRO}-moveit" \
    "ros-${ROS_DISTRO}-ros2-control" \
    "ros-${ROS_DISTRO}-ros2-controllers" \
    "ros-${ROS_DISTRO}-joint-state-publisher" \
    "ros-${ROS_DISTRO}-joint-state-publisher-gui" \
    "ros-${ROS_DISTRO}-urdfdom-py" \
    "ros-${ROS_DISTRO}-python-orocos-kdl-vendor"

success "ROS 2 ${ROS_DISTRO} installed"
info "Activate in this shell: ros2-env ${ROS_DISTRO}"
info "Do not source /opt/ros/... in tracked rc files — it fights uv. See docs/robotics.md."
