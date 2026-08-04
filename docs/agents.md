# Coding agents

[Claude Code](https://docs.anthropic.com/en/docs/claude-code) is the **primary**
AI development tool in this setup (`./bootstrap.sh all` installs it; use `cc`).

[Codex](https://github.com/openai/codex), [OpenCode](https://opencode.ai/), and
[Ollama](https://ollama.com/) are **exploratory** pathways — opt-in, never part
of `all`. Use them to try remote DeepSeek or local models; day-to-day work stays
on Claude Code.

## Install (opt-in)

```sh
./bootstrap.sh codex       # OpenAI Codex CLI
./bootstrap.sh opencode    # OpenCode CLI
./bootstrap.sh ollama      # local model runtime (daemon only)
```

Configs are linked by `./bootstrap.sh link`:

| Tool | Config |
|---|---|
| Claude Code | `~/.claude/settings.json`, `~/.claude/CLAUDE.md` ← `AGENTS.md` |
| Codex | `~/.codex/config.toml` |
| OpenCode | `~/.config/opencode/opencode.json` |

## Shell wrappers

| Command | Tool |
|---|---|
| `cc` / `cc -d` | Claude Code (primary) |
| `cx` / `cx --oss` | Codex (`--oss` → local Ollama) |
| `oc` | OpenCode |

`cc -d` passes `--dangerously-skip-permissions`. Use only in a sandbox or for
tasks you already trust. Do not make `-d` your default.

## Claude Code defaults (`claude/settings.json`)

Tracked defaults (linked to `~/.claude/settings.json`):

| Key | Value | Meaning |
|---|---|---|
| `model` | `opus` | Prefer Opus-class models (higher quality, higher cost) |
| `effortLevel` | `high` | Spend more compute on harder tasks |
| Official plugins | clangd-lsp, code-review | Enabled |

Override per machine in untracked `~/.claude/settings.local.json` (for example
a cheaper default model, or `skipDangerousModePermissionPrompt` if you
accept that risk). The template deliberately does not ship skip-permissions.

## DeepSeek (remote)

1. Put `DEEPSEEK_API_KEY` in `~/.secrets.env` (see `shell/secrets.env.example`).
2. **Codex:** uncomment the DeepSeek `model` / `model_provider` lines in
   `~/.codex/config.toml`, then `cx`.
3. **OpenCode:** `oc` then pick `deepseek/deepseek-chat` (or
   `opencode run -m deepseek/deepseek-chat "…"`).

## Ollama (local)

1. `./bootstrap.sh ollama`, start the daemon (macOS: open the Ollama app).
2. Pull a coding model, e.g. `ollama pull qwen2.5-coder`.
3. **Codex:** `cx --oss` (uses `oss_provider = "ollama"`), or uncomment the
   `local_ollama` defaults in `config.toml`.
4. **OpenCode:** pick `ollama/qwen2.5-coder` (model tags in
   `opencode.json` must match `ollama list`).

## Secrets

| Variable | Used by | Required? |
|---|---|---|
| `ANTHROPIC_API_KEY` | Claude Code | For API-key auth (Claude login may also use OAuth) |
| `OPENAI_API_KEY` | Codex (OpenAI provider) | Only if you use Codex with OpenAI |
| `DEEPSEEK_API_KEY` | Codex / OpenCode DeepSeek | Only if you use DeepSeek |

Never put keys in tracked config files.
