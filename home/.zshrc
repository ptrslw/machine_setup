# .zshrc — zsh INTERACTIVE shell.
#
# Runs in every new interactive zsh (each tab/pane, each nested `zsh`).
# Keep this file to shell-specific glue: prompt syntax and completion differ
# between zsh and bash, so they cannot live in the shared shell/ layer.
# Portable code (aliases, functions, secrets) is sourced from shell/common.sh.
#
# Symlinked: ~/dev/machine_setup/home/.zshrc → ~/.zshrc

# Prompt -----------------------------------------------------------------
# PROMPT_SUBST lets ${VIRTUAL_ENV:...} expand on every prompt redraw, so the
# venv name updates when direnv activates a different .venv after `cd`.
setopt PROMPT_SUBST
# Bold cyan "(venvname) " when a venv is active, then last path segment, then %/#.
#   %B/%b  bold on/off
#   %F{}/%f  color on/off
#   %1~    last path component (tilde-shortened home)
#   %#     "%" for user, "#" for root
export PROMPT="%B%F{cyan}${VIRTUAL_ENV:+(${VIRTUAL_ENV:t}) }%1~%f%b %# "

# direnv ------------------------------------------------------------------
# Loads each project's .envrc on cd (typically activates that project's .venv).
# The hook needs the shell name baked in, so it cannot live in shell/common.sh.
eval "$(direnv hook zsh)"

# Completion --------------------------------------------------------------
# Homebrew ships zsh completions under these paths (Apple Silicon / Intel).
# Harmless no-op on Linux where the directories do not exist.
fpath=(/opt/homebrew/share/zsh/site-functions /usr/local/share/zsh/site-functions $fpath)
autoload -Uz compinit
compinit

# Shared layer ------------------------------------------------------------
# Aliases, cc wrapper, get-status/get-versions/…, secrets, ~/.shell.local.
# See shell/common.sh for load order.
# MACHINE_SETUP_DIR is exported by .zprofile, but .zprofile only runs for LOGIN
# shells — nested `zsh` and most terminal emulators start a non-login shell that
# reads .zshrc alone. Default it here so the source below resolves either way.
: "${MACHINE_SETUP_DIR:=$HOME/dev/machine_setup}"
. "$MACHINE_SETUP_DIR/shell/common.sh"
