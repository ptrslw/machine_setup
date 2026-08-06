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
# Source is the clone kept by installers/agent-skills.sh; pass --update to
# refresh it first. See docs/agents.md.
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
    while IFS= read -r _asy_line; do
        _asy_repo="$(printf '%s' "${_asy_line%%#*}" | tr -d '[:space:]')"
        [ -n "$_asy_repo" ] || continue
        # Matches the layout written by installers/agent-skills.sh (owner__name).
        _asy_src="$_asy_cache/$(printf '%s' "$_asy_repo" | sed 's|/|__|g')"

        if [ ! -d "$_asy_src/.git" ]; then
            echo "agent-skills-sync: $_asy_repo not cached — run ./bootstrap.sh skills" >&2
            _asy_rc=1
            continue
        fi
        [ "$_asy_update" -eq 1 ] && git -C "$_asy_src" pull --ff-only --quiet

        mkdir -p "$_asy_dest"
        cp -R "$_asy_src/skills/." "$_asy_dest/"
        # Repo-level checklists the skills reference; skills alone are incomplete.
        [ -d "$_asy_src/references" ] && cp -R "$_asy_src/references" "$_asy_dest/references"
        echo "agent-skills-sync: $_asy_repo -> $_asy_dest"
    done < "$_asy_manifest"

    _asy_ret=$_asy_rc
    unset _asy_cache _asy_manifest _asy_update _asy_dest _asy_line _asy_repo _asy_src _asy_rc
    return $_asy_ret
}
