#!/usr/bin/env bash
# shell/functions.macos.sh — system helpers for macOS.
# Sourced by shell/functions.sh. Linux counterpart: functions.linux.sh.
#
# Commands: get-sys-info, get-status, get-versions, get-docker, get-process-info

# Static hardware/OS summary (model, CPU, GPU, network, memory).
get-sys-info() {
    local bold='\033[1m' dim='\033[37m' reset='\033[0m'
    local cyan='\033[36m' green='\033[32m' yellow='\033[33m' magenta='\033[35m'
    local label_w=20

    printf "\n${bold}  System Information${reset}\n"
    printf "${dim}  ──────────────────────────────────────${reset}\n"

    local os_pretty
    os_pretty=$(sw_vers -productName 2>/dev/null)" "$(sw_vers -productVersion 2>/dev/null)
    printf "  ${cyan}%-${label_w}s${reset} %s\n" "OS" "${os_pretty:-Unknown}"

    printf "  ${cyan}%-${label_w}s${reset} %s\n" "Kernel" "$(uname -r)"
    printf "  ${cyan}%-${label_w}s${reset} %s\n" "Architecture" "$(uname -m)"
    printf "  ${cyan}%-${label_w}s${reset} %s\n" "Hostname" "$(hostname)"

    # perflevel0 = P-cores on Apple Silicon; else physicalcpu (Intel).
    local cpu_model cpu_cores cpu_threads
    cpu_model=$(sysctl -n machdep.cpu.brand_string 2>/dev/null)
    cpu_cores=$(sysctl -n hw.perflevel0.physicalcpu 2>/dev/null || sysctl -n hw.physicalcpu 2>/dev/null)
    cpu_threads=$(sysctl -n hw.logicalcpu 2>/dev/null)
    printf "\n  ${green}%-${label_w}s${reset} %s\n" "CPU" "${cpu_model:-Unknown}"
    [[ -n "$cpu_cores" ]] && \
        printf "  ${dim}%-${label_w}s${reset} %s cores / %s threads\n" \
            "" "$cpu_cores" "${cpu_threads:-$cpu_cores}"

    # macOS has no sysctl for GPU name — use system_profiler.
    printf "\n"
    local gpu_info
    gpu_info=$(system_profiler SPDisplaysDataType 2>/dev/null \
        | awk -F': ' '/Chipset Model|Chip Model/{print $2}' | head -1)
    local gpu_vram
    gpu_vram=$(system_profiler SPDisplaysDataType 2>/dev/null \
        | awk -F': ' '/VRAM|Total Number of Cores/{print $2}' | head -1)
    if [[ -n "$gpu_info" ]]; then
        printf "  ${magenta}%-${label_w}s${reset} %s" "GPU" "$gpu_info"
        [[ -n "$gpu_vram" ]] && printf "  ${dim}(%s)${reset}" "$gpu_vram"
        printf "\n"
    else
        printf "  ${magenta}%-${label_w}s${reset} Not detected\n" "GPU"
    fi

    # Non-loopback interfaces that have an IPv4 address.
    printf "\n"
    local first_net=1
    local iface ip_addr type_label
    for iface in $(ifconfig -l 2>/dev/null); do
        [[ "$iface" == lo* ]] && continue
        ip_addr=$(ifconfig "$iface" 2>/dev/null | awk '/inet / && !/127.0.0.1/{print $2; exit}')
        [[ -z "$ip_addr" ]] && continue
        case "$iface" in
            en0) type_label="WiFi" ;;
            en*) type_label="ETH" ;;
            *)   type_label="NET" ;;
        esac
        local label="Network"
        [[ $first_net -eq 0 ]] && label=""
        printf "  ${cyan}%-${label_w}s${reset} %-6s ${dim}%-12s${reset} %s\n" \
            "$label" "$type_label" "$iface" "$ip_addr"
        first_net=0
    done

    local gw_ip
    gw_ip=$(route -n get default 2>/dev/null | awk '/gateway:/{print $2}')
    [[ -n "$gw_ip" ]] && \
        printf "  ${dim}%-${label_w}s Gateway %s${reset}\n" "" "$gw_ip"

    local mem_bytes mem_total
    mem_bytes=$(sysctl -n hw.memsize 2>/dev/null)
    if [[ -n "$mem_bytes" ]]; then
        mem_total=$(awk "BEGIN {printf \"%.0f GiB\", $mem_bytes/1024/1024/1024}")
    fi
    printf "\n  ${yellow}%-${label_w}s${reset} %s\n" "Memory" "${mem_total:-Unknown}"

    local hw_model
    hw_model=$(sysctl -n hw.model 2>/dev/null)
    [[ -n "$hw_model" ]] && \
        printf "  ${yellow}%-${label_w}s${reset} %s\n" "Model" "$hw_model"

    echo
}

# Live resource usage: RAM / disk / CPU load, with bar graphs.
get-status() {
    local bold='\033[1m' dim='\033[37m' reset='\033[0m'
    local cyan='\033[36m' green='\033[32m' yellow='\033[33m' magenta='\033[35m'

    # 20-char ASCII bar for a 0–100 percentage.
    # Colors: green <70%, yellow 70–89%, red ≥90%.
    _bar() {
        local pct=$1 width=20 filled=$(( $1 * 20 / 100 ))
        local empty=$(( width - filled ))
        local color=$green
        (( pct >= 70 )) && color=$yellow
        (( pct >= 90 )) && color='\033[31m'
        local bar=""
        for (( i=0; i<filled; i++ )); do bar+="█"; done
        for (( i=0; i<empty; i++ )); do bar+="░"; done
        printf "${color}%s${reset}" "$bar"
    }

    # "Used" ≈ active + wired + compressed pages (matches Activity Monitor).
    printf "\n${bold}${cyan} RAM${reset}  "
    local mem_bytes mem_total_gib page_size pages_active pages_wired pages_compressed
    mem_bytes=$(sysctl -n hw.memsize 2>/dev/null)
    mem_total_gib=$(awk "BEGIN {printf \"%.1f\", $mem_bytes/1024/1024/1024}")
    page_size=$(sysctl -n hw.pagesize 2>/dev/null)
    pages_active=$(vm_stat | awk '/Pages active/{gsub(/\./,"",$3); print $3}')
    pages_wired=$(vm_stat | awk '/Pages wired/{gsub(/\./,"",$4); print $4}')
    pages_compressed=$(vm_stat | awk '/Pages occupied by compressor/{gsub(/\./,"",$5); print $5}')
    local used_bytes=$(( (pages_active + pages_wired + pages_compressed) * page_size ))
    local used_gib=$(awk "BEGIN {printf \"%.1f\", $used_bytes/1024/1024/1024}")
    local ram_pct=$(awk "BEGIN {printf \"%.0f\", $used_bytes/$mem_bytes*100}")
    printf "%s GiB / %s GiB (%s%%)\n" "$used_gib" "$mem_total_gib" "$ram_pct"
    printf "       "; _bar "$ram_pct"; echo

    # Every mounted /dev/* filesystem.
    printf "\n${bold}${green} SSD${reset}\n"
    df -h | awk 'NR>1 && /^\/dev\//' | while read -r dev size used avail pct _rest; do
        local p=${pct%\%}
        printf "  %-18s %6s / %6s  " "$dev" "$used" "$size"
        _bar "$p"
        printf "  %s\n" "$pct"
    done

    # Thread count + 1/5/15-minute load average.
    printf "\n${bold}${yellow} CPU${reset}  "
    local cpu_model ncpu load
    cpu_model=$(sysctl -n machdep.cpu.brand_string 2>/dev/null)
    ncpu=$(sysctl -n hw.logicalcpu 2>/dev/null)
    load=$(sysctl -n vm.loadavg 2>/dev/null | awk '{print $2, $3, $4}')
    printf "%s threads  load %s\n" "$ncpu" "$load"

    # Name only — macOS does not expose a simple utilization counter here.
    printf "\n${bold}${magenta} GPU${reset}  "
    local gpu_name
    gpu_name=$(system_profiler SPDisplaysDataType 2>/dev/null \
        | awk -F': ' '/Chipset Model|Chip Model/{print $2; exit}')
    if [[ -n "$gpu_name" ]]; then
        printf "%s (Metal)\n" "$gpu_name"
    else
        printf "Not detected\n"
    fi
    echo
}

# Installed versions of key development tools.
get-versions() {
    local bold='\033[1m' dim='\033[37m' reset='\033[0m'
    local cyan='\033[36m' green='\033[32m' yellow='\033[33m' magenta='\033[35m'
    local label_w=22

    printf "\n${bold}  Dev tools${reset}\n"
    printf "${dim}  ──────────────────────────────────────${reset}\n"

    if xcode-select -p &>/dev/null; then
        local xcode_ver
        xcode_ver=$(xcodebuild -version 2>/dev/null | head -1 | awk '{print $2}')
        [[ -n "$xcode_ver" ]] && \
            printf "  ${green}%-${label_w}s${reset} %s\n" "Xcode" "$xcode_ver"
    fi

    if command -v brew &>/dev/null; then
        local brew_ver
        brew_ver=$(brew --version 2>/dev/null | head -1 | awk '{print $2}')
        printf "  ${green}%-${label_w}s${reset} %s\n" "Homebrew" "$brew_ver"
    fi

    if command -v python3 &>/dev/null; then
        local py_ver
        py_ver=$(python3 --version 2>&1 | awk '{print $2}')
        printf "  ${yellow}%-${label_w}s${reset} %s\n" "Python" "$py_ver"
    fi

    if command -v uv &>/dev/null; then
        local uv_ver
        uv_ver=$(uv --version 2>/dev/null | awk '{print $2}')
        printf "  ${yellow}%-${label_w}s${reset} %s\n" "uv" "$uv_ver"
    fi

    if command -v node &>/dev/null; then
        printf "  ${yellow}%-${label_w}s${reset} %s\n" "Node.js" "$(node --version 2>/dev/null)"
    fi

    if command -v rustc &>/dev/null; then
        local rust_ver
        rust_ver=$(rustc --version 2>/dev/null | awk '{print $2}')
        printf "  ${yellow}%-${label_w}s${reset} %s\n" "Rust" "$rust_ver"
    fi

    if command -v go &>/dev/null; then
        local go_ver
        go_ver=$(go version 2>/dev/null | awk '{print $3}' | sed 's/go//')
        printf "  ${yellow}%-${label_w}s${reset} %s\n" "Go" "$go_ver"
    fi

    if command -v docker &>/dev/null; then
        local docker_ver
        docker_ver=$(docker --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        printf "  ${yellow}%-${label_w}s${reset} %s\n" "Docker" "$docker_ver"
    fi

    if command -v cmake &>/dev/null; then
        local cmake_ver
        cmake_ver=$(cmake --version 2>/dev/null | head -1 | awk '{print $3}')
        printf "  ${cyan}%-${label_w}s${reset} %s\n" "CMake" "$cmake_ver"
    fi

    if [[ -n "${ROS_DISTRO:-}" ]]; then
        printf "  ${cyan}%-${label_w}s${reset} %s\n" "ROS 2" "$ROS_DISTRO"
    fi

    echo
}

# Local Docker daemon status and container list.
get-docker() {
    local bold='\033[1m' dim='\033[37m' reset='\033[0m'
    local cyan='\033[36m' green='\033[32m' yellow='\033[33m' red='\033[31m'

    _state_color() {
        case "$1" in
            running)  printf "${green}%s${reset}" "$1" ;;
            exited)   printf "${red}%s${reset}" "$1" ;;
            paused)   printf "${yellow}%s${reset}" "$1" ;;
            *)        printf "${dim}%s${reset}" "$1" ;;
        esac
    }

    _show_containers() {
        local label="$1" host="$2"
        local docker_cmd=(docker)
        [[ -n "$host" ]] && docker_cmd=(env "DOCKER_HOST=$host" docker)

        if ! "${docker_cmd[@]}" info &>/dev/null 2>&1; then
            printf "  ${dim}%-20s daemon not reachable${reset}\n" "$label"
            return
        fi

        local ver context_info
        ver=$("${docker_cmd[@]}" version --format '{{.Server.Version}}' 2>/dev/null)
        local security
        security=$("${docker_cmd[@]}" info --format '{{.SecurityOptions}}' 2>/dev/null)
        if [[ "$security" == *rootless* ]]; then
            context_info="rootless"
        else
            context_info="rootful"
        fi
        printf "\n  ${bold}${cyan}%s${reset}  ${dim}Docker %s (%s)${reset}\n" \
            "$label" "${ver:-?}" "$context_info"

        local has_containers=false
        while IFS=$'\t' read -r name image state status ports; do
            if [[ "$has_containers" == false ]]; then
                printf "  ${dim}%-22s %-26s %-12s %s${reset}\n" \
                    "CONTAINER" "IMAGE" "STATE" "STATUS"
                printf "  ${dim}%s${reset}\n" \
                    "──────────────────────────────────────────────────────────────────────────"
                has_containers=true
            fi
            printf "  ${cyan}%-22s${reset} %-26s " "${name:0:22}" "${image:0:26}"
            _state_color "$state"
            printf "  %s\n" "$status"
            if [[ -n "$ports" && "$ports" != "-" ]]; then
                printf "  ${dim}%-22s ↳ %s${reset}\n" "" "$ports"
            fi
        done < <("${docker_cmd[@]}" ps -a \
            --format '{{.Names}}\t{{.Image}}\t{{.State}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null)

        if [[ "$has_containers" == false ]]; then
            printf "  ${dim}  (no containers)${reset}\n"
        fi

        local images_count images_size containers_count volumes_count
        read -r images_count images_size containers_count volumes_count < <(
            "${docker_cmd[@]}" system df --format \
                '{{.Type}}\t{{.TotalCount}}\t{{.Size}}' 2>/dev/null \
            | awk -F'\t' '
                /Images/     {ic=$2; is=$3}
                /Containers/ {cc=$2}
                /Local Volumes/ {vc=$2}
                END {print ic, is, cc, vc}
            '
        )
        printf "\n  ${dim}  %s image(s) (%s)  •  %s container(s)  •  %s volume(s)${reset}\n" \
            "${images_count:-0}" "${images_size:-0B}" \
            "${containers_count:-0}" "${volumes_count:-0}"
    }

    printf "\n${bold}  Docker Status${reset}\n"
    printf "${dim}  ──────────────────────────────────────${reset}\n"

    _show_containers "Local Docker" ""

    echo
}

# Top N processes by resident memory (default 20).
get-process-info() {
    local n=${1:-20}
    local bold='\033[1m' dim='\033[37m' reset='\033[0m' cyan='\033[36m'

    printf "\n${bold}  Top %s Processes by Memory${reset}\n" "$n"
    printf "${dim}  %-24s %10s %7s${reset}\n" "PROCESS" "RAM" "CPU%"
    printf "${dim}  ────────────────────────────────────────────${reset}\n"

    ps -Amcr -o rss=,pcpu=,comm= \
        | sort -rnk1 \
        | head -n "$n" \
        | while read -r rss cpu comm; do
            [[ -z "$rss" || "$rss" -eq 0 ]] 2>/dev/null && continue
            local ram=""
            if (( rss >= 1048576 )); then
                ram=$(awk "BEGIN {printf \"%.1f GiB\", $rss/1048576}")
            elif (( rss >= 1024 )); then
                ram=$(awk "BEGIN {printf \"%.0f MiB\", $rss/1024}")
            else
                ram="${rss} KiB"
            fi
            printf "  ${cyan}%-24s${reset} %10s %6s%%\n" "${comm##*/}" "$ram" "$cpu"
        done
    echo
}
