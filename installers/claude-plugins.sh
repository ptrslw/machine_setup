#!/usr/bin/env bash
# installers/claude-plugins.sh — install the Claude Code marketplaces/plugins
# declared in claude/settings.json (the single source of truth).
#
# `extraKnownMarketplaces` + `enabledPlugins` in that file make Claude Code
# load the plugins; this script performs the fetch/install ahead of time so a
# freshly provisioned machine has them on disk before the first `claude` run.
#
# Requires Claude Code (installers/claude-code.sh) and jq (packages/).
# Invoked by `bootstrap.sh claude`, not by the generic packages installer loop.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

SETTINGS="$SCRIPT_DIR/../claude/settings.json"
DRY_RUN="${DRY_RUN:-false}"

header "Claude Code plugins"

if ! is_cmd claude; then
    error "claude not found. Run installers/claude-code.sh first."
    exit 1
fi
if ! is_cmd jq; then
    error "jq not found. Run 'bootstrap.sh packages' first."
    exit 1
fi

# Run a claude subcommand; on failure print captured stderr and return 1.
claude_try() {
    local out rc
    set +e
    out="$(claude "$@" 2>&1)"
    rc=$?
    set -e
    if [[ "$rc" -ne 0 ]]; then
        error "claude $* failed (exit $rc)"
        [[ -n "$out" ]] && printf '%s\n' "$out" >&2
        return 1
    fi
    return 0
}

# --- Marketplaces -----------------------------------------------------------
# Only github-backed marketplaces are declared here; `claude plugin marketplace
# add` takes the owner/repo shorthand directly.
known=""
[[ "$DRY_RUN" == "true" ]] || known="$(claude plugin marketplace list --json 2>/dev/null || echo '[]')"

while IFS=$'\t' read -r name repo; do
    [[ -n "$name" ]] || continue
    if [[ "$DRY_RUN" == "true" ]]; then
        info "[DRY RUN] would ensure marketplace $name ($repo)"
        continue
    fi
    if jq -e --arg n "$name" 'any(.[]; .name == $n)' <<<"$known" >/dev/null; then
        claude_try plugin marketplace update "$name"
        success "marketplace $name up to date"
    else
        claude_try plugin marketplace add "$repo" --scope user
        success "marketplace $name added ($repo)"
    fi
done < <(jq -r '
    (.extraKnownMarketplaces // {})
    | to_entries[]
    | select(.value.source.source == "github")
    | [.key, .value.source.repo]
    | @tsv
' "$SETTINGS")

# --- Plugins ----------------------------------------------------------------
installed=""
[[ "$DRY_RUN" == "true" ]] || installed="$(claude plugin list --json 2>/dev/null || echo '[]')"

while IFS= read -r id; do
    [[ -n "$id" ]] || continue
    if [[ "$DRY_RUN" == "true" ]]; then
        info "[DRY RUN] would ensure plugin $id (scope: user)"
        continue
    fi
    if jq -e --arg id "$id" 'any(.[]; .id == $id and .scope == "user")' <<<"$installed" >/dev/null; then
        claude_try plugin update "$id"
        success "plugin $id updated"
    else
        claude_try plugin install "$id" --scope user
        success "plugin $id installed"
    fi
done < <(jq -r '
    (.enabledPlugins // {})
    | to_entries[]
    | select(.value != false)
    | .key
' "$SETTINGS")
