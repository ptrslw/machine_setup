#!/usr/bin/env bash
# Provision a machine from this repo (macOS or Ubuntu Linux).
#
# Usage: ./bootstrap.sh [command] [options]
#
# Commands:
#   link        Symlink home/ into $HOME (backs up existing files)
#   packages    Homebrew (macOS) or apt (Ubuntu), then installers/
#   claude      Claude Code CLI + tracked plugins (needs Node from `packages`)
#   skills      Skill packs from packages/agent-skills.txt into every agent
#   doctor      Read-only configuration report
#   all         link → packages → claude → skills → doctor (default)
#
# Opt-in agents (exploratory; Claude Code remains primary — see docs/agents.md):
#   codex       OpenAI Codex CLI
#   opencode    OpenCode CLI
#   ollama      Ollama local model runtime
#
# Opt-in robotics (Ubuntu; never part of `all` — see docs/robotics.md):
#   ros2        Install ROS 2 Jazzy
#   gazebo      Install Gazebo Harmonic + ROS 2 bridge
#   isaac       Prerequisites check + Omniverse Launcher steps for Isaac Sim
#
# Options:
#   --dry-run       Print actions without applying them
#   --list          List the steps that make up `all` and exit
#   --only <step>   Run one step of `all` (link|packages|claude|skills|doctor).
#                   Overrides the command; equivalent to naming that step.
#   -h, --help      Show this help
#
# No secrets in this repo. See docs/secrets.md.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

STEPS=(link packages claude skills doctor)

# --- Argument parsing -------------------------------------------------------
COMMAND="all"
DRY_RUN=false
LIST_ONLY=false
ONLY_STEP=""

COMMAND_SET=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)      DRY_RUN=true; shift ;;
        --list)         LIST_ONLY=true; shift ;;
        --only)
            ONLY_STEP="${2:-}"
            if [[ -z "$ONLY_STEP" ]]; then
                error "--only requires a step name (link|packages|claude|skills|doctor)"
                exit 1
            fi
            shift 2
            ;;
        -h|--help)
            sed -n '2,33p' "$0" | sed -E 's/^# ?//'
            exit 0
            ;;
        -*) error "Unknown option: $1"; exit 1 ;;
        *)
            if [[ "$COMMAND_SET" == "true" ]]; then
                error "Unexpected argument: $1"
                exit 1
            fi
            COMMAND="$1"
            COMMAND_SET=true
            shift
            ;;
    esac
done

export DRY_RUN

if [[ "$LIST_ONLY" == "true" ]]; then
    echo -e "\n${BOLD}  Steps that make up 'all'${NC}"
    echo -e "${DIM}  ────────────────────────────────────${NC}"
    for s in "${STEPS[@]}"; do
        printf "  ${GREEN}%-10s${NC}\n" "$s"
    done
    echo -e "\n${BOLD}  Opt-in agents (not in 'all')${NC}"
    echo -e "${DIM}  ────────────────────────────────────${NC}"
    for s in codex opencode ollama; do
        printf "  ${CYAN}%-10s${NC}\n" "$s"
    done
    echo -e "\n${BOLD}  Opt-in robotics (not in 'all')${NC}"
    echo -e "${DIM}  ────────────────────────────────────${NC}"
    for s in ros2 gazebo isaac; do
        printf "  ${CYAN}%-10s${NC}\n" "$s"
    done
    echo
    exit 0
fi

# --- Steps ------------------------------------------------------------------

run_link() {
    header "Linking dotfiles"
    local home_src="$SCRIPT_DIR/home"

    # *.example files are templates for untracked per-user files
    # (git identity, etc.). Never symlink them into $HOME — the user copies
    # and fills them in by hand.
    while IFS= read -r -d '' file; do
        local rel="${file#"$home_src"/}"
        symlink_with_backup "$file" "$HOME/$rel"
    done < <(find "$home_src" -type f -not -name '*.example' -print0)

    # Agent guidance + Claude settings live outside home/ but still link into $HOME.
    mkdir -p "$HOME/.claude"
    symlink_with_backup "$SCRIPT_DIR/AGENTS.md" "$HOME/.claude/CLAUDE.md"
    symlink_with_backup "$SCRIPT_DIR/claude/settings.json" "$HOME/.claude/settings.json"
}

run_packages() {
    header "Installing packages ($OS)"

    if [[ "$OS" == "macos" ]]; then
        if ! is_cmd brew; then
            if [[ "$DRY_RUN" == "true" ]]; then
                info "[DRY RUN] would install Homebrew"
            else
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
        fi
        if [[ "$DRY_RUN" == "true" ]]; then
            info "[DRY RUN] would run: brew bundle --file $SCRIPT_DIR/packages/Brewfile"
        else
            brew bundle --file "$SCRIPT_DIR/packages/Brewfile"
        fi
        info "Personal extras (not installed): brew bundle --file $SCRIPT_DIR/packages/Brewfile.optional"
    elif [[ "$OS" == "ubuntu" ]]; then
        local pkgs=()
        while IFS= read -r line; do
            [[ -z "$line" || "$line" == \#* ]] && continue
            pkgs+=("$line")
        done < "$SCRIPT_DIR/packages/apt.txt"

        if [[ "$DRY_RUN" == "true" ]]; then
            info "[DRY RUN] would run: sudo apt-get update && sudo apt-get install -y ${pkgs[*]}"
        else
            sudo apt-get update -qq
            sudo apt-get install -y "${pkgs[@]}"
        fi
    else
        warn "Unrecognized OS ($OS) — skipping package install (supported: macos, ubuntu)"
    fi

    # Core installers only (installers/*.sh). Opt-in agents/robotics live under
    # installers/optional/ and are invoked by named bootstrap commands.
    for installer in "$SCRIPT_DIR"/installers/*.sh; do
        [[ -f "$installer" ]] || continue
        [[ "$(basename "$installer")" == "claude-code.sh" ]] && continue
        if [[ "$DRY_RUN" == "true" ]]; then
            info "[DRY RUN] would run: $installer"
        else
            bash "$installer"
        fi
    done
}

run_claude() {
    header "Installing Claude Code"
    local script
    for script in "$SCRIPT_DIR/installers/claude-code.sh" \
                  "$SCRIPT_DIR/installers/claude-plugins.sh"; do
        if [[ "$DRY_RUN" == "true" ]]; then
            info "[DRY RUN] would run: $script"
        else
            bash "$script"
        fi
    done
}

run_skills() {
    header "Installing agent skill packs"
    local script="$SCRIPT_DIR/installers/agent-skills.sh"
    if [[ "$DRY_RUN" == "true" ]]; then
        info "[DRY RUN] would run: $script"
    else
        bash "$script"
    fi
}

# Opt-in installer. $1 = script basename without .sh (ros2|gazebo|isaac-sim|…).
run_optional() {
    local name="$1"
    local script="$SCRIPT_DIR/installers/optional/${name}.sh"
    if [[ ! -f "$script" ]]; then
        error "Optional installer not found: $script"
        return 1
    fi
    bash "$script"
}

# shellcheck disable=SC2088  # tildes in messages are display text, not paths
run_doctor() {
    header "Doctor — machine configuration report"

    echo -e "  ${CYAN}OS${NC}      $OS"
    echo -e "  ${CYAN}Arch${NC}    $ARCH"
    [[ -n "${UBUNTU_VERSION:-}" ]] && echo -e "  ${CYAN}Ubuntu${NC}  $UBUNTU_VERSION"
    echo

    echo -e "  ${BOLD}Tools${NC}"
    local tool
    for tool in git tmux nvim direnv uv node npm docker gh rg fzf jq wezterm; do
        if is_cmd "$tool"; then
            local ver
            ver=$("$tool" --version 2>/dev/null | head -1)
            printf "    ${GREEN}✓${NC} %-10s %s\n" "$tool" "$ver"
        else
            printf "    ${DIM}✗ %-10s not installed${NC}\n" "$tool"
        fi
    done
    echo

    echo -e "  ${BOLD}Agents${NC}"
    if is_cmd claude; then
        printf "    ${GREEN}✓${NC} %-10s %s  ${DIM}(primary)${NC}\n" "claude" "$(claude --version 2>/dev/null | head -1)"
    else
        printf "    ${DIM}✗ %-10s not installed  (./bootstrap.sh claude)${NC}\n" "claude"
    fi
    for tool in codex opencode ollama; do
        if is_cmd "$tool"; then
            printf "    ${GREEN}✓${NC} %-10s %s\n" "$tool" "$("$tool" --version 2>/dev/null | head -1)"
        else
            printf "    ${DIM}✗ %-10s not installed  (./bootstrap.sh %s)${NC}\n" "$tool" "$tool"
        fi
    done
    if curl -sf --max-time 1 http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
        printf '    %b✓%b ollama daemon reachable on :11434\n' "$GREEN" "$NC"
    elif is_cmd ollama; then
        printf '    %b  ollama installed but daemon not responding on :11434%b\n' "$DIM" "$NC"
    fi
    echo

    echo -e "  ${BOLD}Claude plugins${NC}  ${DIM}(declared in claude/settings.json)${NC}"
    if ! is_cmd claude || ! is_cmd jq; then
        printf '    %b✗ needs claude and jq to report%b\n' "$DIM" "$NC"
    else
        local installed_plugins
        installed_plugins="$(claude plugin list --json 2>/dev/null || echo '[]')"
        local id
        while IFS= read -r id; do
            [[ -n "$id" ]] || continue
            if jq -e --arg id "$id" 'any(.[]; .id == $id and .scope == "user")' \
                <<<"$installed_plugins" >/dev/null; then
                printf "    ${GREEN}✓${NC} %s\n" "$id"
            else
                printf "    ${RED}✗${NC} %s (not installed — run './bootstrap.sh claude')\n" "$id"
            fi
        done < <(jq -r '(.enabledPlugins // {}) | to_entries[] | select(.value != false) | .key' \
            "$SCRIPT_DIR/claude/settings.json")
    fi
    echo

    # Skill packs are agent-neutral (packages/agent-skills.txt); each agent
    # gets them through its own mechanism, and two of them are per-project.
    echo -e "  ${BOLD}Agent skills${NC}  ${DIM}(packages/agent-skills.txt)${NC}"
    local cache_dir="${AGENT_SKILLS_CACHE:-$HOME/.cache/agent-skills}"
    local repo
    while IFS= read -r repo; do
        repo="${repo%%#*}"
        repo="$(echo "$repo" | tr -d '[:space:]')"
        [[ -n "$repo" ]] || continue
        printf "    ${CYAN}%s${NC}\n" "$repo"

        local market=""
        if is_cmd jq; then
            market="$(jq -r --arg repo "$repo" '
                (.extraKnownMarketplaces // {}) | to_entries[]
                | select(.value.source.repo == $repo) | .key
            ' "$SCRIPT_DIR/claude/settings.json" | head -1)"
        fi
        if [[ -n "$market" ]]; then
            printf "      ${GREEN}✓${NC} %-12s declared (marketplace %s)\n" "Claude Code" "$market"
        else
            printf "      ${RED}✗${NC} %-12s not declared in claude/settings.json\n" "Claude Code"
        fi

        local agent
        for agent in codex gemini; do
            if is_cmd "$agent"; then
                printf "      ${GREEN}✓${NC} %-12s installed — './bootstrap.sh skills' wires the pack in\n" "$agent"
            else
                printf "      ${DIM}· %-12s not installed${NC}\n" "$agent"
            fi
        done

        if [[ -d "$cache_dir/${repo//\//__}/.git" ]]; then
            printf "      ${GREEN}✓${NC} %-12s %s (agent-skills-sync)\n" "cache" "$cache_dir/${repo//\//__}"
        else
            printf "      ${RED}✗${NC} %-12s not cloned — run './bootstrap.sh skills'\n" "cache"
        fi
    done < "$SCRIPT_DIR/packages/agent-skills.txt"
    echo

    echo -e "  ${BOLD}Symlinks${NC}"
    local home_src="$SCRIPT_DIR/home"
    while IFS= read -r -d '' file; do
        local rel="${file#"$home_src"/}"
        local dest="$HOME/$rel"
        if [[ -L "$dest" && "$(readlink "$dest")" == "$file" ]]; then
            printf "    ${GREEN}✓${NC} %s\n" "$dest"
        elif [[ -e "$dest" ]]; then
            printf "    ${RED}✗${NC} %s (real file, not linked — run 'bootstrap.sh link')\n" "$dest"
        else
            printf "    ${RED}✗${NC} %s (missing)\n" "$dest"
        fi
    done < <(find "$home_src" -type f -not -name '*.example' -print0)

    if [[ -L "$HOME/.claude/CLAUDE.md" && "$(readlink "$HOME/.claude/CLAUDE.md")" == "$SCRIPT_DIR/AGENTS.md" ]]; then
        printf "    ${GREEN}✓${NC} %s\n" "$HOME/.claude/CLAUDE.md"
    else
        printf "    ${RED}✗${NC} %s (missing or not linked)\n" "$HOME/.claude/CLAUDE.md"
    fi
    if [[ -L "$HOME/.claude/settings.json" && "$(readlink "$HOME/.claude/settings.json")" == "$SCRIPT_DIR/claude/settings.json" ]]; then
        printf "    ${GREEN}✓${NC} %s\n" "$HOME/.claude/settings.json"
    else
        printf "    ${RED}✗${NC} %s (missing or not linked)\n" "$HOME/.claude/settings.json"
    fi
    echo

    echo -e "  ${BOLD}Secrets${NC}"
    if [[ -f "$HOME/.secrets.env" ]]; then
        local perms
        perms=$(stat -f '%Lp' "$HOME/.secrets.env" 2>/dev/null || stat -c '%a' "$HOME/.secrets.env" 2>/dev/null)
        if [[ "$perms" == "600" ]]; then
            success "~/.secrets.env exists, permissions 600"
        else
            warn "~/.secrets.env exists but permissions are $perms (expected 600) — run: chmod 600 ~/.secrets.env"
        fi
    else
        warn "~/.secrets.env not found — copy shell/secrets.env.example and fill it in (see docs/secrets.md)"
    fi

    echo -e "\n  ${BOLD}Git identity${NC}"
    if [[ -f "$HOME/.gitconfig.local" ]]; then
        success "~/.gitconfig.local exists"
    else
        warn "~/.gitconfig.local not found — copy home/.gitconfig.local.example and fill in your name/email"
    fi

    # Robotics extras — informational only; missing is not a failure.
    echo -e "\n  ${BOLD}Robotics (optional)${NC}"
    if [[ -d /opt/ros ]]; then
        local d
        for d in /opt/ros/*/; do
            [[ -d "$d" ]] || continue
            printf "    ${GREEN}✓${NC} ROS 2 %s\n" "$(basename "$d")"
        done
    else
        printf '    %b✗ ROS 2 not installed  (./bootstrap.sh ros2)%b\n' "$DIM" "$NC"
    fi
    if is_cmd gz; then
        printf '    %b✓%b Gazebo (gz)\n' "$GREEN" "$NC"
    else
        printf '    %b✗ Gazebo not installed  (./bootstrap.sh gazebo)%b\n' "$DIM" "$NC"
    fi
    if [[ -d "$HOME/.local/share/ov/pkg" ]]; then
        printf '    %b✓%b Omniverse / Isaac under ~/.local/share/ov/pkg\n' "$GREEN" "$NC"
    else
        printf '    %b✗ Isaac Sim not detected  (./bootstrap.sh isaac)%b\n' "$DIM" "$NC"
    fi
    echo
}

# --- Dispatch ---------------------------------------------------------------

echo -e "\n${BOLD}machine_setup${NC}"
echo -e "  ${CYAN}OS${NC}    ${OS} ${CYAN}Arch${NC} ${ARCH}"
[[ "$DRY_RUN" == "true" ]] && echo -e "  ${YELLOW}Mode${NC}  dry-run (no changes will be made)"

# --only <step> always wins (runs that single all-step regardless of COMMAND).
RUN_LIST=()
if [[ -n "$ONLY_STEP" ]]; then
    case "$ONLY_STEP" in
        link|packages|claude|skills|doctor) RUN_LIST=("$ONLY_STEP") ;;
        *)
            error "--only expects link|packages|claude|skills|doctor (got: $ONLY_STEP)"
            exit 1
            ;;
    esac
else
    case "$COMMAND" in
        all)                              RUN_LIST=("${STEPS[@]}") ;;
        link|packages|claude|skills|doctor) RUN_LIST=("$COMMAND") ;;
        codex|opencode|ollama|ros2|gazebo|isaac) RUN_LIST=("$COMMAND") ;;
        *)
            error "Unknown command: $COMMAND (expected: link|packages|claude|skills|doctor|all|codex|opencode|ollama|ros2|gazebo|isaac)"
            exit 1
            ;;
    esac
fi

FAILED=()
for step in "${RUN_LIST[@]}"; do
    set +e
    case "$step" in
        link)     run_link ;;
        packages) run_packages ;;
        claude)   run_claude ;;
        skills)   run_skills ;;
        doctor)   run_doctor ;;
        codex)    run_optional codex ;;
        opencode) run_optional opencode ;;
        ollama)   run_optional ollama ;;
        ros2)     run_optional ros2 ;;
        gazebo)   run_optional gazebo ;;
        isaac)    run_optional isaac-sim ;;
        *)
            error "Unknown step: $step"
            FAILED+=("$step")
            set -e
            continue
            ;;
    esac
    rc=$?
    set -e
    [[ $rc -ne 0 ]] && FAILED+=("$step")
done

echo
if [[ ${#FAILED[@]} -gt 0 ]]; then
    error "Failed steps: ${FAILED[*]}"
    exit 1
fi

[[ "$DRY_RUN" == "true" ]] && echo -e "${YELLOW}Dry run complete — no changes made.${NC}\n" || echo -e "${GREEN}Done.${NC}\n"
