# Contributing

PRs are welcome if they improve clarity or fix something real. This stays a
personal setup repo — keep changes small and consistent with the existing
contracts.

## Before opening a PR

1. Conventional Commits (`feat:`, `fix:`, `docs:`, …)
2. `pre-commit install` once, then `pre-commit run --all-files`
3. Scan the diff for secrets (public repo)
4. Keybinding changes update [docs/keybindings.md](docs/keybindings.md) in the
   same commit
5. Tool changes update the README tool-choices table and the right manifest
   (`packages/Brewfile`, `packages/Brewfile.optional`, or `packages/apt.txt`)

## Where things go

| Change | Location |
|---|---|
| Portable aliases / wrappers | `shell/aliases.sh` |
| OS-specific helpers | `shell/functions.macos.sh` / `functions.linux.sh` |
| Login `PATH` / `EDITOR` | `home/.zprofile` / `home/.profile` |
| Prompt / direnv / completion | `home/.zshrc` / `home/.bashrc` |
| Machine-only overrides | untracked `~/.shell.local` |
| Secrets | untracked `~/.secrets.env` |

One-off personal apps belong in `packages/Brewfile.optional`, not the core
Brewfile that `bootstrap.sh all` installs.
