#!/usr/bin/env sh
# shell/aliases.sh — portable aliases and small wrappers.
# Sourced by shell/common.sh. POSIX-sh only (no bash/zsh-only syntax).

# Neovim replaced Vim. Keep `vim` working for muscle memory / scripts that call it.
alias vim='nvim'
alias vi='nvim'

# cc — Claude Code (primary AI development tool).
#
#   cc          normal session (permission prompts on)
#   cc -d ...   "dangerous" mode: --dangerously-skip-permissions
#               Use only in a sandbox / disposable environment, or when you
#               already trust the whole task. Extra args pass through to `claude`.
cc() {
    if [ "$1" = "-d" ]; then
        shift
        claude --dangerously-skip-permissions "$@"
    else
        claude "$@"
    fi
}

# Exploratory agent pathways (not primary — see docs/agents.md).
#   cx …        OpenAI Codex CLI  (./bootstrap.sh codex)
#   cx --oss …  Codex against local Ollama
#   oc …        OpenCode CLI      (./bootstrap.sh opencode)
cx() { codex "$@"; }
oc() { opencode "$@"; }
