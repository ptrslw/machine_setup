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
        claude plugin marketplace update "$name" >/dev/null
        success "marketplace $name up to date"
    else
        claude plugin marketplace add "$repo" --scope user >/dev/null
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
        claude plugin update "$id" >/dev/null 2>&1 || true
        success "plugin $id already installed"
    else
        claude plugin install "$id" --scope user >/dev/null
        success "plugin $id installed"
    fi
done < <(jq -r '
    (.enabledPlugins // {})
    | to_entries[]
    | select(.value != false)
    | .key
' "$SETTINGS")
