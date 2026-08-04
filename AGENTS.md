# AGENTS.md

Machine-wide instructions for coding agents. Claude Code is the primary AI
tool in this machine setup; Codex / OpenCode are exploratory (see
`docs/agents.md`).

`bootstrap.sh link` symlinks this file to `~/.claude/CLAUDE.md`, so every
Claude Code session on this machine loads it — regardless of which repo you
are in. A project may ship its own `CLAUDE.md` / `AGENTS.md`; those take
precedence inside that project.

This file is public. Do not add hostnames, personal IPs, account names, or
other one-person infrastructure details.

Supported platforms: macOS and Linux (Ubuntu).

## Machine layout

- Repos live under `~/dev/`.
- Dotfiles in `$HOME` (`.zshrc`, `.tmux.conf`, `.wezterm.lua`, `.gitconfig`,
  …) are symlinks into `~/dev/machine_setup/home/`. Editing `~/.zshrc` edits
  this repo — check `git status` here and commit.
- `~/.secrets.env` and `~/.shell.local` are real files, never tracked. See
  Secrets below. (`~/.zshrc.local` is still sourced as a legacy fallback.)

## Toolchain defaults

- **Python:** `uv` only. No bare `pip`, no root/global venv. Each project
  owns a `.venv`, activated by direnv via that project's `.envrc`.
  - Inside a project with Ruff/mypy declared as deps (or as dev-deps):
    `uv run ruff …`, `uv run mypy …`, `uv run pytest …`
  - Ad-hoc one-shots with no project env: `uvx ruff check .` is fine
  - Prefer `uv run` for the verification protocol below so the same
    locked toolchain is used as CI/pre-commit
- **Shell:** POSIX-sh for anything shared by bash and zsh
  (`shell/common.sh`). Shell-specific syntax only in `.zshrc` / `.bashrc`.
- **Commits:** Conventional Commits (`feat:`, `fix:`, `docs:`, `refactor:`,
  `test:`, …).

## Verification protocol

Before declaring Python work done, run all three — do not skip any:

1. `uv run ruff check src/ tests/`
2. `uv run mypy src/`
3. `uv run pytest tests/`

Run `mypy` over all of `src/`, never a single file. Pre-commit usually
checks the whole tree; checking only touched files misses cross-file type
errors (a signature change in one file breaking a caller in another).

## Secrets

- Read credentials from environment variables only (loaded from
  `~/.secrets.env`, never tracked — see `docs/secrets.md`).
- Never write a credential into a file that is or could become tracked by
  git, in any repo.
- Never echo, log, or print a secret into a transcript, commit message, or
  file.
- Before committing or opening a PR in this repo, scan the diff for anything
  that looks like a key or token — this repo is public.

## Provisioning a new machine

```sh
git clone git@github.com:ptrslw/machine_setup.git ~/dev/machine_setup
cd ~/dev/machine_setup
cp home/.gitconfig.local.example ~/.gitconfig.local   # fill in name/email
cp shell/secrets.env.example ~/.secrets.env && chmod 600 ~/.secrets.env
./bootstrap.sh --dry-run all   # review first
./bootstrap.sh all
./bootstrap.sh doctor          # symlinks, identity, secrets file
pre-commit install
```

Identity and secrets are per-human, per-machine. When provisioning for
someone else, ask for their name/email for `~/.gitconfig.local` — do not
copy values from elsewhere in this repo or its history. Do not fill
`~/.secrets.env` from ambient credentials (e.g. the agent's own env) unless
the human operating the machine explicitly provides those values for that
machine.

`doctor` is read-only; safe to re-run anytime. Partial use without full
bootstrap: `docs/using.md`.
