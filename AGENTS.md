# AGENTS.md

This document establishes machine-wide directives for coding agents. It is symlinked to `~/.claude/CLAUDE.md`, applying universally unless overridden by a project-specific configuration. 

## Objective Problem Solving

When analyzing issues or designing systems, optimize for the objectively correct, architecturally sound approach. 

*   **Exclude Effort Estimations:** Do not factor development speed, perceived complexity, or the "path of least resistance" into solution proposals. 
*   **Prioritize Correctness:** Present the optimal solution based strictly on technical merit.

## Machine Layout

*   **Repositories:** Located under `~/dev/`.
*   **Dotfiles:** Managed in `$HOME` (e.g., `.zshrc`, `.tmux.conf`) as symlinks to `~/dev/machine_setup/home/`. Modifications to these files edit the `machine_setup` repository; verify with `git status` and commit accordingly.
*   **Untracked Files:** `~/.secrets.env` and `~/.shell.local` are real files and must never be tracked by version control. 

## Coding Standards & Toolchain Defaults

*   **Python:** Strictly utilize `uv`. Do not use bare `pip` or global virtual environments. Each project manages a `.venv` activated by `direnv`. Adhere strictly to PEP 8 standards. Complete static type hinting is mandatory.
*   **C++:** Conform strictly to the Google C++ Style Guide for formatting, naming, and structural paradigms.
*   **Shell Scripts:** Enforce POSIX-sh compliance for scripts shared across bash and zsh (`shell/common.sh`). Confine shell-specific syntax to `.zshrc` or `.bashrc`.
*   **Version Control:** Adhere strictly to Conventional Commits (`feat:`, `fix:`, `docs:`, etc.).

## Verification Protocol (Python)

When operating within a Python project equipped with the relevant dependencies, execute the following deterministic sequence before declaring modifications complete. Adapt paths (e.g., `src/`, `tests/`) to match the local repository structure.

1.  `uv run ruff check [source_dirs] [test_dirs]`
2.  `uv run mypy [source_dirs]`
3.  `uv run pytest [test_dirs]`

*Constraint:* Execute `mypy` across the entire source directory tree. Do not target isolated files, as this fails to detect cross-file type regressions.

## Security and Secrets

*   **Retrieval:** Extract credentials exclusively from environment variables loaded via `~/.secrets.env`.
*   **Prohibitions:** Never write credentials into tracked files. Never output secrets into transcripts, logs, commit messages, or terminal output.
*   **Review:** Scan all diffs for leaked keys or tokens prior to committing or opening pull requests.