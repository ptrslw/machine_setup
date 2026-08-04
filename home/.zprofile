# .zprofile — zsh LOGIN shell.
#
# Runs once when you open a login shell (before .zshrc). Put environment that
# should exist exactly once per session here: PATH, MACHINE_SETUP_DIR, EDITOR.
#
# Do NOT put prompt, aliases, or completion here — those belong in .zshrc.
# Putting PATH edits in .zshrc re-appends on every nested shell and makes
# debugging "why is my PATH huge?" painful.
#
# Symlinked: ~/dev/machine_setup/home/.zprofile → ~/.zprofile

# Root of this repo. shell/common.sh uses it to find aliases.sh / functions.sh.
# Override here if you cloned somewhere other than ~/dev/machine_setup.
export MACHINE_SETUP_DIR="$HOME/dev/machine_setup"

# Homebrew (macOS). Apple Silicon: /opt/homebrew; Intel: /usr/local.
# `brew shellenv` prints the exports that put Homebrew on PATH.
# Guarded so this is a no-op on Linux.
if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# uv and tools installed via `uv tool` live in ~/.local/bin.
# This is the ONLY Python-related PATH entry in the whole setup:
#   - no python.org framework path
#   - no `alias python3=...` (aliases don't apply to scripts)
# uv owns interpreter selection; each project gets its own .venv via direnv.
# See docs/workflow.md for the history behind that choice.
export PATH="$HOME/.local/bin:$PATH"

# Neovim is the CLI editor ($EDITOR for git, crontab, etc.). Config: ~/.config/nvim
export EDITOR="nvim"
export LANG="en_US.UTF-8"
