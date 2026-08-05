# .profile — bash/sh LOGIN shell (Linux counterpart to .zprofile).
#
# Same rules as .zprofile: PATH and env once per session. Prompt/aliases go
# in .bashrc. See .zprofile for the longer explanation of why.
#
# Symlinked: ~/dev/machine_setup/home/.profile → ~/.profile

export MACHINE_SETUP_DIR="$HOME/dev/machine_setup"

# No Homebrew branch on purpose — Homebrew is macOS-only in this repo.
# uv / `uv tool` binaries.
export PATH="$HOME/.local/bin:$PATH"

# Neovim is the CLI editor ($EDITOR for git, crontab, etc.). Config: ~/.config/nvim
export EDITOR="nvim"
export LANG="en_US.UTF-8"

# Bash reads .profile for LOGIN shells and .bashrc for interactive non-login
# shells — never both. Without this hook a login bash (tmux pane, ssh session)
# gets no prompt, aliases, or direnv. zsh needs no equivalent: it reads
# .zprofile and .zshrc for a login shell.
if [ -n "${BASH_VERSION:-}" ] && [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
fi
