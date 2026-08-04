# .bashrc — bash INTERACTIVE shell (Linux counterpart to .zshrc).
#
# Same rule as .zshrc: shell-specific glue only. Portable code lives in
# shell/common.sh so bash and zsh stay in sync.
#
# Symlinked: ~/dev/machine_setup/home/.bashrc → ~/.bashrc

# Prompt ------------------------------------------------------------------
# \[...\] marks non-printing escape sequences so bash's line-wrapping math
# stays correct (without them, long lines wrap mid-command).
# Bold cyan "(venvname) " when $VIRTUAL_ENV is set (direnv/uv), then cwd, then $.
PS1='\[\033[1;36m\]${VIRTUAL_ENV:+($(basename "$VIRTUAL_ENV")) }\W\[\033[0m\] \$ '

# direnv — see .zshrc for why this cannot live in the shared layer.
eval "$(direnv hook bash)"

# Shared aliases, functions, secrets, machine-local overrides.
. "$MACHINE_SETUP_DIR/shell/common.sh"
