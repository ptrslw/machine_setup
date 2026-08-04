#!/usr/bin/env sh
# shell/common.sh — portable layer sourced by both .zshrc and .bashrc.
#
# Stay POSIX-sh compatible: no arrays, no [[ ]], no bash/zsh-only syntax.
# Both shells source this file, so a bash-ism here breaks zsh (and vice versa).
#
# Where things belong (see README "Shell contract"):
#   PATH / login setup           → .zprofile / .profile
#   prompt, completion, direnv   → .zshrc / .bashrc  (syntax differs)
#   aliases / portable functions → this file and what it sources
#   secrets                      → ~/.secrets.env     (untracked, mode 600)
#   machine-specific overrides   → ~/.shell.local     (untracked)
#
# Expected clone path is ~/dev/machine_setup. Override MACHINE_SETUP_DIR in
# .zprofile / .profile if you put the repo elsewhere.

: "${MACHINE_SETUP_DIR:=$HOME/dev/machine_setup}"

# Colored ls on both platforms.
export CLICOLOR=1
export LSCOLORS="Exfxcxdxbxegedabagacad"       # BSD ls (macOS)
export LS_COLORS="${LS_COLORS:-}"              # GNU ls (Linux); empty → defaults

. "$MACHINE_SETUP_DIR/shell/aliases.sh"
# functions.sh picks functions.macos.sh or functions.linux.sh via uname.
. "$MACHINE_SETUP_DIR/shell/functions.sh"

# Secrets -----------------------------------------------------------------
# API keys/tokens live ONLY in ~/.secrets.env — never in a tracked file.
# `set -a` makes every assignment in the sourced file automatically exported
# into the environment; `set +a` turns that off again afterward.
# See docs/secrets.md and shell/secrets.env.example.
if [ -f "$HOME/.secrets.env" ]; then
    set -a
    . "$HOME/.secrets.env"
    set +a
fi

# Machine-local overrides -------------------------------------------------
# Hostnames, personal IPs, one-off aliases for this box only. Untracked so
# the public repo never encodes one person's network. Sourced last so it can
# override anything above.
# Prefer ~/.shell.local (works for bash and zsh). ~/.zshrc.local still works
# as a fallback for older machines.
if [ -f "$HOME/.shell.local" ]; then
    . "$HOME/.shell.local"
elif [ -f "$HOME/.zshrc.local" ]; then
    . "$HOME/.zshrc.local"
fi
