# Using this repo

Supported platforms: **macOS** and **Linux (Ubuntu)**.

This is my working setup. If you want parts of it, pick how deep to go.

| Approach | When | What to do |
|---|---|---|
| **Full provision** | New machine, willing to take the whole stack | [Quick start](../README.md#quick-start), then [after bootstrap](../README.md#after-bootstrap) |
| **Cherry-pick** | Keep your shell/IDE; borrow ideas | Copy configs or conventions below |
| **Read only** | Comparing tools or reading decisions | README [tool choices](../README.md#tool-choices) and [shell contract](../README.md#shell-contract) |

## Cherry-pick

Useful without running `bootstrap.sh all`:

1. **Keybindings** — [keybindings.md](keybindings.md)
2. **Python layout** — uv + per-project `.venv` + direnv ([workflow.md](workflow.md#python-project-from-scratch))
3. **Git** — Conventional Commits; identity in `~/.gitconfig.local`
4. **Agents** — Claude Code primary; rest optional ([agents.md](agents.md))
5. **Secrets** — `~/.secrets.env` mode 600 only ([secrets.md](secrets.md))

Configs worth copying directly: `home/.tmux.conf`, `home/.wezterm.lua`,
`home/.config/nvim/init.lua`, pieces of `shell/`.

## Not in `all`

- Exploratory agents: `./bootstrap.sh codex|opencode|ollama`
- Robotics (Ubuntu): `./bootstrap.sh ros2|gazebo|isaac`
- macOS extras: `packages/Brewfile.optional`
