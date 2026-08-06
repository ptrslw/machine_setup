#!/usr/bin/env sh
# shell/functions.sh — load the agent helpers and the OS-specific ones.
#
# Sourced by shell/common.sh. This file stays POSIX-sh; the files it loads
# may use bash-isms (arithmetic, arrays). That is fine: they are sourced into
# an interactive bash/zsh shell, not executed as standalone scripts.
#
# Available after load (both platforms): get-sys-info, get-status,
# get-versions, get-docker, get-process-info, agent-skills-sync.
# Linux also: ros2-env (see docs/robotics.md).

: "${MACHINE_SETUP_DIR:=$HOME/dev/machine_setup}"

. "$MACHINE_SETUP_DIR/shell/functions.agents.sh"

case "$(uname -s)" in
    Darwin)
        . "$MACHINE_SETUP_DIR/shell/functions.macos.sh"
        ;;
    Linux)
        . "$MACHINE_SETUP_DIR/shell/functions.linux.sh"
        ;;
esac
