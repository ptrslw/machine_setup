#!/usr/bin/env bash
# shell/functions.agents.sh — OS-neutral helpers for coding agents.
# Sourced by shell/functions.sh into an interactive bash/zsh shell (the
# hyphenated name, like get-status, needs one of those — not dash).
#
# Commands: agent-skills-sync

# agent-skills-sync [dest] — copy the skill packs declared in
# packages/agent-skills.txt into the current project, for agents that have no
# user-global mechanism (Cursor, OpenCode). Default dest: .cursor/skills
# (OpenCode reads a project-root skills/ instead: agent-skills-sync skills).
#
# Source is the SHA-pinned clone kept by installers/agent-skills.sh; pass
# --update to re-fetch the pinned SHA (never floats on main). See docs/agents.md.
agent-skills-sync() {
    _asy_cache="${AGENT_SKILLS_CACHE:-$HOME/.cache/agent-skills}"
    _asy_manifest="$MACHINE_SETUP_DIR/packages/agent-skills.txt"
    _asy_update=0
    _asy_dest=".cursor/skills"

    while [ $# -gt 0 ]; do
        case "$1" in
            --update) _asy_update=1; shift ;;
            -h|--help)
                echo "usage: agent-skills-sync [--update] [dest]  (default dest: .cursor/skills)"
                unset _asy_cache _asy_manifest _asy_update _asy_dest
                return 0
                ;;
            *) _asy_dest="$1"; shift ;;
        esac
    done

    if [ ! -f "$_asy_manifest" ]; then
        echo "agent-skills-sync: manifest not found: $_asy_manifest" >&2
        unset _asy_cache _asy_manifest _asy_update _asy_dest
        return 1
    fi

    _asy_rc=0
    while IFS= read -r _asy_line || [ -n "$_asy_line" ]; do
        # Strip comments and whitespace (keep in sync with lib/common.sh).
        _asy_entry="${_asy_line%%#*}"
        _asy_entry="${_asy_entry#"${_asy_entry%%[![:space:]]*}"}"
        _asy_entry="${_asy_entry%"${_asy_entry##*[![:space:]]}"}"
        [ -n "$_asy_entry" ] || continue

        case "$_asy_entry" in
            */*@*)
                _asy_repo="${_asy_entry%@*}"
                _asy_sha="${_asy_entry##*@}"
                ;;
            *)
                echo "agent-skills-sync: expected owner/repo@sha, got: $_asy_entry" >&2
                _asy_rc=1
                continue
                ;;
        esac
        case "$_asy_sha" in
            *[!0-9a-fA-F]*)
                echo "agent-skills-sync: pin must be hex SHA (got: $_asy_sha)" >&2
                _asy_rc=1
                continue
                ;;
        esac
        if [ "${#_asy_sha}" -ne 40 ]; then
            echo "agent-skills-sync: pin must be a full 40-char hex SHA (got: $_asy_sha)" >&2
            _asy_rc=1
            continue
        fi

        # Matches the layout written by installers/agent-skills.sh (owner__name).
        _asy_src="$_asy_cache/$(printf '%s' "$_asy_repo" | sed 's|/|__|g')"

        if [ ! -d "$_asy_src/.git" ]; then
            echo "agent-skills-sync: $_asy_repo not cached — run ./bootstrap.sh skills" >&2
            _asy_rc=1
            continue
        fi

        if [ "$_asy_update" -eq 1 ]; then
            if ! GIT_TERMINAL_PROMPT=0 git -C "$_asy_src" fetch --depth 1 origin "$_asy_sha" \
                || ! git -C "$_asy_src" checkout --detach --quiet FETCH_HEAD; then
                echo "agent-skills-sync: failed to fetch $_asy_repo@$_asy_sha" >&2
                _asy_rc=1
                continue
            fi
        fi

        _asy_head="$(git -C "$_asy_src" rev-parse HEAD 2>/dev/null || true)"
        _asy_sha_lc="$(printf '%s' "$_asy_sha" | tr 'A-F' 'a-f')"
        if [ "$_asy_head" != "$_asy_sha_lc" ]; then
            echo "agent-skills-sync: cache at $_asy_head, manifest pins $_asy_sha_lc — run ./bootstrap.sh skills or pass --update" >&2
            _asy_rc=1
            continue
        fi

        mkdir -p "$_asy_dest"
        cp -R "$_asy_src/skills/." "$_asy_dest/"
        # Repo-level checklists the skills reference; skills alone are incomplete.
        [ -d "$_asy_src/references" ] && cp -R "$_asy_src/references" "$_asy_dest/references"
        echo "agent-skills-sync: $_asy_repo@$_asy_sha_lc -> $_asy_dest"
    done < "$_asy_manifest"

    _asy_ret=$_asy_rc
    unset _asy_cache _asy_manifest _asy_update _asy_dest _asy_line _asy_entry \
        _asy_repo _asy_sha _asy_sha_lc _asy_src _asy_head _asy_rc
    return $_asy_ret
}
