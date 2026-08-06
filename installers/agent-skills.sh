#!/usr/bin/env bash
# installers/agent-skills.sh — install the skill packs declared in
# packages/agent-skills.txt into every agent on this machine that supports a
# user-global mechanism, and keep a local clone pinned to the declared SHA.
#
# Manifest lines are owner/repo@sha (full 40-char hex). One adapter per agent:
#   Claude Code  declared in claude/settings.json; installed by
#                installers/claude-plugins.sh. This script only verifies that
#                the manifest and that file agree.
#   Codex        codex plugin marketplace add <repo>      (if codex present)
#   Gemini CLI   gemini skills install <url> --path skills (if gemini present)
#   Cursor /     no user-global mechanism exists — the pack is cloned at the
#   OpenCode     pinned SHA under ~/.cache/agent-skills/ and `agent-skills-sync`
#                copies it into a project on demand (shell/functions.agents.sh).
#
# Invoked by `bootstrap.sh skills`. Requires git; jq for the Claude check.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

MANIFEST="$SCRIPT_DIR/../packages/agent-skills.txt"
SETTINGS="$SCRIPT_DIR/../claude/settings.json"
CACHE_DIR="${AGENT_SKILLS_CACHE:-$HOME/.cache/agent-skills}"
DRY_RUN="${DRY_RUN:-false}"

header "Agent skills"

if [[ ! -f "$MANIFEST" ]]; then
    error "Manifest not found: $MANIFEST"
    exit 1
fi

# Claude Code: settings.json holds the enable switch, so the manifest is only
# honored there if the two agree. Warn loudly rather than rewriting a tracked
# file during provisioning.
check_claude() {
    local repo="$1"
    if ! is_cmd jq; then
        warn "jq not found — skipping the Claude Code declaration check"
        return 0
    fi
    local market
    market="$(jq -r --arg repo "$repo" '
        (.extraKnownMarketplaces // {})
        | to_entries[]
        | select(.value.source.repo == $repo)
        | .key
    ' "$SETTINGS" | head -1)"

    if [[ -z "$market" ]]; then
        warn "Claude Code: $repo is not in extraKnownMarketplaces of claude/settings.json — add it, then './bootstrap.sh claude'"
        return 0
    fi
    if jq -e --arg m "@$market" '
        (.enabledPlugins // {})
        | to_entries
        | any(.[]; (.key | endswith($m)) and .value != false)
    ' "$SETTINGS" >/dev/null; then
        success "Claude Code: declared via marketplace $market (installed by 'bootstrap.sh claude')"
    else
        warn "Claude Code: marketplace $market is declared but no plugin from it is in enabledPlugins"
    fi
}

# Codex >= 0.122 reads the pack's root skills/ via its own plugin marketplace.
# The CLI has no SHA pin; we still pass only owner/repo.
install_codex() {
    local repo="$1"
    is_cmd codex || return 0
    if ! codex plugin --help >/dev/null 2>&1; then
        info "Codex: installed version has no 'plugin' command — skipping (needs >= 0.122)"
        return 0
    fi
    if [[ "$DRY_RUN" == "true" ]]; then
        info "[DRY RUN] Codex: would run 'codex plugin marketplace add $repo'"
        return 0
    fi
    local out rc
    set +e
    out="$(codex plugin marketplace add "$repo" 2>&1)"
    rc=$?
    set -e
    if [[ "$rc" -eq 0 ]]; then
        success "Codex: marketplace $repo added/updated"
    else
        warn "Codex: 'codex plugin marketplace add $repo' failed (exit $rc)"
        [[ -n "$out" ]] && printf '%s\n' "$out" >&2
    fi
}

install_gemini() {
    local repo="$1"
    is_cmd gemini || return 0
    if [[ "$DRY_RUN" == "true" ]]; then
        info "[DRY RUN] Gemini: would run 'gemini skills install https://github.com/$repo.git --path skills'"
        return 0
    fi
    local out rc
    set +e
    out="$(gemini skills install "https://github.com/$repo.git" --path skills 2>&1)"
    rc=$?
    set -e
    if [[ "$rc" -eq 0 ]]; then
        success "Gemini CLI: skills installed from $repo"
    else
        warn "Gemini CLI: 'gemini skills install https://github.com/$repo.git --path skills' failed (exit $rc)"
        [[ -n "$out" ]] && printf '%s\n' "$out" >&2
    fi
}

# A pack that fails does not stop the others; the exit status still reports it.
packs=0
failed=()
parse_errors=0
while IFS= read -r line || [[ -n "$line" ]]; do
    rc=0
    agent_skill_parse_entry "$line" || rc=$?
    if [[ "$rc" -eq 1 ]]; then
        continue # blank / comment
    elif [[ "$rc" -gt 1 ]]; then
        parse_errors=$((parse_errors + 1))
        continue
    fi
    packs=$((packs + 1))
    repo="$AGENT_SKILL_REPO"
    sha="$AGENT_SKILL_SHA"
    dest="$(agent_skill_cache_path "$repo" "$CACHE_DIR")"

    info "pack: $repo@$sha"
    check_claude "$repo"
    install_codex "$repo"
    install_gemini "$repo"
    agent_skill_ensure_cache "$dest" "$repo" "$sha" || failed+=("$repo@$sha")
done < "$MANIFEST"

if [[ "$parse_errors" -gt 0 ]]; then
    error "Invalid entries in $MANIFEST"
    exit 1
fi

if [[ "$packs" -eq 0 ]]; then
    warn "No packs declared in $MANIFEST"
    exit 0
fi

if is_cmd cursor || is_cmd opencode; then
    info "Cursor/OpenCode are per-project: run 'agent-skills-sync' inside a repo to copy the packs in"
fi

if [[ ${#failed[@]} -gt 0 ]]; then
    error "Failed packs: ${failed[*]}"
    exit 1
fi
