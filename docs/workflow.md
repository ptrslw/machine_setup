# Workflow

Detail behind the [README](../README.md#development-workflow) summary —
how the pieces connect and why. Platforms: macOS and Ubuntu.

Borrowing pieces without a full bootstrap: [using.md](using.md).

## Terminal → tmux → project

1. [WezTerm](https://wezfurlong.org/wezterm/) starts and runs
   `tmux new-session -A -s main` as its `default_prog` (`home/.wezterm.lua`).
   - `-A` means attach-or-create: a second WezTerm window joins the same
     tmux session instead of starting a new one.
   - Prefer tmux windows (`prefix c`) and panes (`prefix |` / `prefix -`)
     over extra sessions. Full chord sheet: [keybindings.md](keybindings.md).
2. `cd` into a project. If it has an `.envrc`,
   [direnv](https://direnv.net/) activates that project's
   [uv](https://docs.astral.sh/uv/)-managed `.venv` (first time:
   `direnv allow .`). The prompt shows `(venvname)`.
3. Edit with [Neovim](https://neovim.io/) for quick terminal work (`nvim`, or
   `vim` — aliased), open a GUI IDE for the language (below), or launch
   [Claude Code](https://docs.anthropic.com/en/docs/claude-code) with
   `cc` / `cc -d` (primary AI tool; `-d` only for trusted/sandboxed tasks).
   Exploratory agents: [agents.md](agents.md).

## IDE

| Language / role | Tool |
|---|---|
| Python | [Cursor](https://cursor.com/) or [VS Code](https://code.visualstudio.com/) |
| C / C++ | [CLion](https://www.jetbrains.com/clion/) |
| Terminal / `$EDITOR` | [Neovim](https://neovim.io/) — baseline, not a full IDE |

macOS: Brewfile casks. Linux: install CLion / Cursor / VS Code / Sublime Merge
from the vendor (not in `apt.txt`).

## Git

CLI: [Git](https://git-scm.com/) + [GitHub CLI](https://cli.github.com/).
GUI: [Sublime Merge](https://www.sublimemerge.com/). Identity in
`~/.gitconfig.local` (see README Personal identity).

## Neovim as the CLI editor

Config is Lua (`home/.config/nvim/init.lua`), not a Vimscript `.vimrc`.
`bootstrap.sh link` symlinks it to `~/.config/nvim/init.lua`. On first
launch, that file bootstraps [lazy.nvim](https://github.com/folke/lazy.nvim)
into Neovim's data directory; the plugin list starts empty so you can add
LSP, treesitter, and so on as separate specs without bloating the floor.

Reserved `<Space>` namespaces in [keybindings.md](keybindings.md) (`SPC f`,
`SPC g`, …) are for future plugins — they do nothing until you add them.
Cursor / CLion / VS Code own IDE features; Neovim stays the thin `$EDITOR`.

`$EDITOR` is `nvim` (set in `.zprofile` / `.profile`). Install via
`./bootstrap.sh packages`.

## Why tmux owns multiplexing

WezTerm *can* split panes, but then you have two systems competing for
keybindings (Ctrl+b vs a GUI leader). Pick one.

tmux wins because the same config works over SSH into a headless Linux box.
WezTerm is then just the GPU-accelerated renderer plus font/color config.
The tab bar hides when there is only one tab so it stays out of the way.

## Why uv owns Python

Before this setup, a python.org framework build and a Homebrew `python3`
alias both claimed the name `python3` — and they disagreed between
interactive shells (where aliases apply) and scripts (where they do not).
Silent version skew is hard to debug.

The rule here: neither a framework install nor a shell alias touches
`python3`. `uv python install 3.12` manages the interpreter; each project
gets `uv venv` → `.venv` → `.envrc` that direnv activates on `cd`. There is
no global venv to keep in sync.

## Python project from scratch

How I start a new app or library:

```sh
mkdir -p ~/dev/myproject && cd ~/dev/myproject
uv init                  # or: uv init --package
uv python pin 3.12
uv venv
uv add ruff mypy pytest  # adjust to the project
cat > .envrc <<'EOF'
source .venv/bin/activate
EOF
direnv allow .
```

Then day-to-day:

```sh
uv run ruff check src/ tests/
uv run ruff format src/ tests/
uv run mypy src/
uv run pytest tests/
```

Use `uv run` inside the project so the locked environment is used. Reserve
`uvx` for one-off tools outside a project. See [AGENTS.md](../AGENTS.md)
verification protocol.

Example `.envrc` for a robotics workspace that also needs ROS:

```sh
# example — robotics project only
source /opt/ros/jazzy/setup.bash
source .venv/bin/activate
```

## Handy commands

| Command | Purpose |
|---|---|
| `get-sys-info` | Static hardware / OS summary |
| `get-status` | Live RAM / disk / CPU (GPU when tools exist) |
| `get-versions` | Key dev-tool versions |
| `get-docker` | Local Docker status and containers |
| `get-process-info [N]` | Top N processes by RSS (default 20) |
| `ros2-env [distro]` | Source ROS 2 into this shell only (Linux) |

## Machine-local overrides

Values true for exactly one machine (a personal Tailscale IP, a one-off SSH
alias) go in `~/.shell.local`. `shell/common.sh` sources it last. Legacy
name `~/.zshrc.local` still works. The file is real, untracked, and never
leaves that machine — that is how this public repo stays generic.

## Robotics (optional)

ROS 2 / Gazebo / Isaac Sim are opt-in Ubuntu extras — never part of
`bootstrap.sh all`. See [robotics.md](robotics.md).
