# machine_setup

Dotfiles and provisioning for macOS and Ubuntu. MIT. Partial adopt without
full bootstrap: [docs/using.md](docs/using.md). Agent rules: [AGENTS.md](AGENTS.md).

## Quick start

```sh
git clone git@github.com:ptrslw/machine_setup.git ~/dev/machine_setup
cd ~/dev/machine_setup
cp home/.gitconfig.local.example ~/.gitconfig.local && $EDITOR ~/.gitconfig.local
cp shell/secrets.env.example ~/.secrets.env && chmod 600 ~/.secrets.env
$EDITOR ~/.secrets.env
./bootstrap.sh --dry-run all
./bootstrap.sh all
./bootstrap.sh doctor
pre-commit install
```

Post-bootstrap: `gh auth login`; run `claude` once for auth; per Python
project `.envrc` + `direnv allow .`. Opt-in agents:
`./bootstrap.sh codex|opencode|ollama`. macOS extras not in `all`:
`brew bundle --file packages/Brewfile.optional`.

## Tool choices

| Role | Choice | Why |
|---|---|---|
| Terminal | [WezTerm](https://wezfurlong.org/wezterm/) | GPU renderer, Lua config, same binary on macOS and Linux. Multiplexing delegated to tmux so keybindings do not fork. |
| Multiplexer | [tmux](https://github.com/tmux/tmux) | One config for local and SSH. Survives terminal disconnect. |
| Shell | zsh (macOS), bash (Ubuntu) | Platform defaults. Portable logic in `shell/` only. |
| CLI editor | [Neovim](https://neovim.io/) | `$EDITOR` for commits and remote shells. Not used as a full IDE. |
| Python IDE | [Cursor](https://cursor.com/) / [VS Code](https://code.visualstudio.com/) | Cursor when the session is agent-assisted; VS Code otherwise. Both cross-platform. |
| C/C++ IDE | [CLion](https://www.jetbrains.com/clion/) | Best cross-platform CMake + debugger workflow in my experience. |
| Git CLI | [Git](https://git-scm.com/) + [gh](https://cli.github.com/) | `gh` covers PRs/issues without leaving the terminal. |
| Git GUI | [Sublime Merge](https://www.sublimemerge.com/) | Fast hunk/line staging; maps cleanly to underlying git commands. |
| Git hooks | [pre-commit](https://pre-commit.com/) | Runs gitleaks, shellcheck, shfmt, and basic file checks before each commit. Config: `.pre-commit-config.yaml`. Also runs in CI. |
| Python | [uv](https://docs.astral.sh/uv/) + [direnv](https://direnv.net/) | uv owns interpreter + venv; direnv activates per-project `.envrc` on `cd`. Avoids global `python3` / alias skew. |
| Lint / types | [Ruff](https://docs.astral.sh/ruff/), [mypy](https://mypy-lang.org/) | Ruff for lint/format speed; mypy for static types. Invoked via `uv run` in projects. |
| AI (primary) | [Claude Code](https://docs.anthropic.com/en/docs/claude-code) | Strongest agent loop for my day-to-day work. Installed by `all`; wrapper `cc`. |
| AI skills | [agent-skills](https://github.com/addyosmani/agent-skills) | Addy Osmani's pack of production-grade engineering workflows for coding agents: 24 lifecycle skills (spec-driven development, TDD, incremental implementation, code review, security hardening, performance, observability, shipping), 4 subagents (code reviewer, security auditor, test engineer, web performance auditor), and slash commands `/spec`, `/planning`, `/build`, `/test`, `/review`, `/webperf`, `/code-simplify`, `/ship`. Declared as a SHA pin in `packages/agent-skills.txt` and installed by `all` into every agent present. See [docs/agents.md](docs/agents.md). |
| AI (opt-in) | [Codex](https://github.com/openai/codex), [OpenCode](https://opencode.ai/), [Ollama](https://ollama.com/) | Secondary paths for DeepSeek / local models. Not in `all`. See [docs/agents.md](docs/agents.md). |
| Robotics (opt-in) | ROS 2, Gazebo, Isaac Sim | Ubuntu / NVIDIA only. Never in `all`. See [docs/robotics.md](docs/robotics.md). |

Swap procedure: update this table → package manifest or dotfile →
`./bootstrap.sh packages` (or `link`).

## Runtime stack

WezTerm `default_prog` → `tmux new-session -A -s main`. tmux owns panes/splits
(`Ctrl+b`). WezTerm defines no leader. Detach: prefix + `d` (exit closes the
pane). Keybinding grammar: [docs/keybindings.md](docs/keybindings.md).

Neovim: `home/.config/nvim/init.lua`, Space leader, empty lazy.nvim plugin
list. GUI IDEs own language intelligence.

```sh
./bootstrap.sh ros2|gazebo|isaac   # Ubuntu; activate ROS with ros2-env
```

Do not source `/opt/ros/...` from tracked rc files — conflicts with uv.

Workflow detail: [docs/workflow.md](docs/workflow.md).

### Shell helpers

| Command | Function |
|---|---|
| `get-sys-info` | Hardware / OS |
| `get-status` | RAM / disk / CPU (/ GPU) |
| `get-versions` | Tool versions |
| `get-docker` | Daemon + containers |
| `get-process-info [N]` | Top RSS processes |
| `agent-skills-sync [dest]` | Copy skill packs into this project (Cursor / OpenCode) |
| `ros2-env [distro]` | Source ROS 2 (Linux) |

## Shell contract

| File | Runs | Contents |
|---|---|---|
| `.zprofile` / `.profile` | login, once | `PATH`, `MACHINE_SETUP_DIR`, brew (macOS), `EDITOR`, `LANG` |
| `.zshrc` / `.bashrc` | interactive | prompt, completion, direnv; sources `shell/common.sh` |
| `shell/common.sh` | via rc | aliases, functions, secrets, `~/.shell.local` |
| `shell/aliases.sh` | via common | aliases; `cc` / `cx` / `oc` |
| `shell/functions.sh` | via common | → `functions.agents.sh`, `functions.{macos,linux}.sh` |

| Item | Location | Forbidden in |
|---|---|---|
| `PATH` | `.zprofile` / `.profile` | rc files |
| Prompt / completion / direnv | `.zshrc` / `.bashrc` | `shell/` |
| Aliases / wrappers | `shell/aliases.sh` | — |
| Secrets | `~/.secrets.env` (mode 600) | tracked files |
| Per-project env | project `.envrc` | rc files |
| Host-specific | `~/.shell.local` | tracked files |

## Secrets and identity

- Secrets: `~/.secrets.env`, mode 600, loaded by `shell/common.sh`. Names in
  `shell/secrets.env.example`. Policy: [docs/secrets.md](docs/secrets.md).
- Git identity: `~/.gitconfig.local` (from `home/.gitconfig.local.example`);
  not in tracked `.gitconfig`.
- Claude risk flags (e.g. skip-permissions): `~/.claude/settings.local.json`,
  not tracked `claude/settings.json`.
- `AGENTS.md` → `~/.claude/CLAUDE.md` via `bootstrap.sh link`.

## Layout

```
machine_setup/
├── bootstrap.sh              # link | packages | claude | skills | doctor | all
├── lib/common.sh
├── packages/                 # Brewfile, Brewfile.optional, apt.txt,
│                             #   agent-skills.txt
├── installers/               # uv, node, docker, wezterm, claude-code,
│                             #   claude-plugins, agent-skills
│   └── optional/             # codex, opencode, ollama, ros2, gazebo, isaac
├── home/                     # → $HOME
├── shell/
├── claude/settings.json      # → ~/.claude/settings.json (model + plugins)
├── AGENTS.md                 # → ~/.claude/CLAUDE.md
└── docs/
```

## Extending

1. macOS core → `packages/Brewfile`; macOS extras → `Brewfile.optional`;
   Ubuntu → `packages/apt.txt` or `installers/`.
2. `./bootstrap.sh packages`
3. Shell hooks → `shell/` per contract
4. Update [tool choices](#tool-choices)

## Verify

```sh
./bootstrap.sh doctor
```

Read-only: OS/arch, tools, Claude plugins (`claude/settings.json`), skill
packs per agent (`packages/agent-skills.txt`), symlinks (incl. Claude
settings), secrets mode, git identity.
