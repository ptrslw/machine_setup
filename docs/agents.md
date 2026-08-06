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

## Claude Code plugins

`claude/settings.json` declares Claude Code's plugin set:
`extraKnownMarketplaces` for the marketplaces, `enabledPlugins` for what loads
in every session. `./bootstrap.sh claude` runs `installers/claude-plugins.sh`,
which reads that file and performs the marketplace add/update plus the
user-scope plugin install, so a new machine has them on disk before the first
`claude` run. Re-running only updates.

| Plugin | Marketplace | Source |
|---|---|---|
| `clangd-lsp` | `claude-plugins-official` | `anthropics/claude-plugins-official` |
| `code-review` | `claude-plugins-official` | `anthropics/claude-plugins-official` |
| `agent-skills` | `addy-agent-skills` | [`addyosmani/agent-skills`](https://github.com/addyosmani/agent-skills) |

Add a plugin by adding it to `enabledPlugins` (plus `extraKnownMarketplaces`
if it comes from a new marketplace), then `./bootstrap.sh claude`.

## Skill packs (all agents)

Skill packs are not Claude-specific, so the declaration of intent is not
either: `packages/agent-skills.txt` lists the packs this machine wants, one
`owner/repo@sha` per line (full 40-char hex). Skill packs steer agents that
run shell and edit trees — bump the SHA only after reviewing the upstream
diff. `./bootstrap.sh skills` runs `installers/agent-skills.sh`, which
translates that list into whatever each installed agent supports.

| Agent | Mechanism | Scope | Pin |
|---|---|---|---|
| Claude Code | marketplace plugin, declared in `claude/settings.json` | user-global | marketplace floats until Claude grows pin support |
| Codex (≥ 0.122) | `codex plugin marketplace add <repo>` | user-global | CLI has no pin |
| Gemini CLI | `gemini skills install <url> --path skills` | user-global | CLI has no pin |
| Cursor | `.cursor/skills/` | **per-project** | local cache @ SHA |
| OpenCode | project `skills/` | **per-project** | local cache @ SHA |

No directory is read by every agent, so "install globally" only exists for the
first three; the installer skips any agent that is not present. Cursor and
OpenCode read skills per project by design, so the installer instead keeps a
SHA-pinned clone at `~/.cache/agent-skills/<owner>__<repo>` and
`agent-skills-sync` copies it into the project you are in:

```sh
agent-skills-sync              # → ./.cursor/skills   (Cursor)
agent-skills-sync skills       # → ./skills           (OpenCode)
agent-skills-sync --update     # re-fetch the pinned SHA (does not float on main)
```

The copy includes the pack's repo-level `references/`; skills that cite those
checklists are incomplete without them. For an agent none of this covers,
`npx skills add <owner>/<repo>` handles 70+ others.

`./bootstrap.sh doctor` reports both layers: which declared Claude plugins are
installed, and for each pack whether Claude has it declared, whether the
cache is at the pinned SHA, and whether Codex/Gemini are merely present on
PATH (doctor does not claim those packs are wired — their CLIs have no
reliable query yet).

The one pack installed today, `addyosmani/agent-skills`, supplies 24 lifecycle
skills (spec-driven development, TDD, incremental implementation, code review,
security hardening, performance, observability, shipping), 4 subagents (code
reviewer, security auditor, test engineer, web performance auditor), and slash
commands `/spec`, `/planning`, `/build`, `/test`, `/review`, `/webperf`,
`/code-simplify`, `/ship`.

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
