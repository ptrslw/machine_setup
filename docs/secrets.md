# Secrets

This repo is public. Credentials are never committed here.

## Where secrets live

| Location | Tracked? | Purpose |
|---|---|---|
| `~/.secrets.env` | no | Real values. Mode `600` (owner read/write only). Loaded by `shell/common.sh` in every interactive shell. |
| `shell/secrets.env.example` | yes | Expected variable *names* (required vs optional). Never a real value. |
| `~/.shell.local` | no | Non-secret but personal/machine-specific values (hostname, Tailscale IP). Legacy: `~/.zshrc.local`. |

**Mode 600** means: owner can read and write; group and others have no access.
That keeps API keys off other accounts on a shared machine. Set it with
`chmod 600 ~/.secrets.env`.

Only fill keys you use. The example file marks Claude’s key as the primary
agent pathway; everything else is optional personal automation or exploratory
agents.

## New machine

```sh
cp shell/secrets.env.example ~/.secrets.env
chmod 600 ~/.secrets.env
$EDITOR ~/.secrets.env
```

`./bootstrap.sh doctor` checks that the file exists and is mode `600`.

## Adding a secret

1. Add the variable name (and a `# where to get it` comment) to
   `shell/secrets.env.example`, under the right required/optional section.
2. Put the real value in `~/.secrets.env` on each machine that needs it.
3. Nowhere else — not under `home/`, not in `claude/settings.json`, not in
   `.codex/config.toml` / `opencode.json`, not in comments or commit messages.

## Defense in depth

- `.gitignore` excludes `secrets.env`, `*.local`, and `.dotfiles-backup/`
  (backups from `bootstrap.sh link` can hold old secrets).
- Pre-commit runs [gitleaks](https://github.com/gitleaks/gitleaks) on every
  commit; CI runs the same hooks on pull requests.
- Optional manual check before a push:
  ```sh
  git grep -nE 'sk-ant-|sk-proj-|xoxb-|xapp-|AIza[0-9A-Za-z_-]{35}'
  ```

## If a secret leaks

1. Rotate it at the provider immediately. Deleting it in a later commit does
   **not** remove it from git history.
2. If the repo was already pushed, scrub history (`git filter-repo` or BFG)
   and force-push only after confirming nothing else depends on the old
   history.
