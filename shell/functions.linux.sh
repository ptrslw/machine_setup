#!/usr/bin/env bash
# shell/functions.linux.sh — system helpers for Linux (Ubuntu).
# Sourced by shell/functions.sh. macOS counterpart: functions.macos.sh.
#
# Commands: get-status, get-versions, get-sys-info, get-docker, get-process-info,
#           ros2-env

# ros2-env [distro] — source ROS 2 into the *current* shell only.
# Default distro: jazzy (override: ros2-env humble, or ROS_DISTRO=…).
# Do not put this in .profile/.bashrc permanently — it fights uv. Use per
# session, or source from a robotics project's .envrc via direnv.
ros2-env() {
    local distro="${1:-${ROS_DISTRO:-jazzy}}"
    local prefix="/opt/ros/${distro}"

    if [[ ! -d "$prefix" ]]; then
        echo "ros2-env: ${prefix} not found. Install with: ./bootstrap.sh ros2" >&2
        return 1
    fi

    # Prefer the shell-native setup script when present.
    if [[ -n "${ZSH_VERSION:-}" && -f "${prefix}/setup.zsh" ]]; then
        # shellcheck disable=SC1090
        source "${prefix}/setup.zsh"
    elif [[ -f "${prefix}/setup.bash" ]]; then
        # shellcheck disable=SC1090
        source "${prefix}/setup.bash"
    elif [[ -f "${prefix}/setup.sh" ]]; then
        # shellcheck disable=SC1090
        source "${prefix}/setup.sh"
    else
        echo "ros2-env: no setup script under ${prefix}" >&2
        return 1
    fi

    echo "ros2-env: sourced ${distro} (ROS_DISTRO=${ROS_DISTRO:-$distro})"
}

# Live resource usage: RAM / disk / CPU temp / GPU, with bar graphs.
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

    printf "\n${bold}${cyan} RAM${reset}  "
    free -h | awk '/^Mem:/ {printf "%s / %s (%.1f%%)\n", $3, $2, $3/$2*100}'
    local ram_pct
    ram_pct=$(free | awk '/^Mem:/ {printf "%.0f", $3/$2*100}')
    printf "       "; _bar "$ram_pct"; echo

    # Real block devices only (skip tmpfs / devtmpfs / efivarfs).
    printf "\n${bold}${green} SSD${reset}\n"
    df -h --output=source,size,used,avail,pcent -x tmpfs -x devtmpfs -x efivarfs 2>/dev/null \
        | grep -E '^/dev/' | while read -r dev size used avail pct; do
        local p=${pct%\%}
        printf "  %-18s %6s / %6s  " "$dev" "$used" "$size"
        _bar "$p"
        printf "  %s\n" "$pct"
    done

    # Prefer lm-sensors; fall back to /sys/class/thermal.
    printf "\n${bold}${yellow} CPU${reset}  "
    if command -v sensors &>/dev/null; then
        local temps min max count
        temps=$(sensors 2>/dev/null | grep -oP 'Core \d+:\s+\+\K[0-9.]+' | sort -rn)
        min=$(echo "$temps" | tail -1)
        max=$(echo "$temps" | head -1)
        count=$(echo "$temps" | wc -l)
        if [[ -n "$max" ]]; then
            if [[ "$min" == "$max" ]]; then
                printf "%s cores @ ${yellow}%s°C${reset}\n" "$count" "$max"
            else
                printf "%s cores  ${yellow}%s–%s°C${reset}\n" "$count" "$min" "$max"
            fi
        fi
    else
        for zone in /sys/class/thermal/thermal_zone*/; do
            if [[ -f "${zone}temp" ]]; then
                local temp type
                temp=$(cat "${zone}temp")
                type=$(cat "${zone}type" 2>/dev/null || echo "unknown")
                printf "%s: %.1f°C  " "$type" "$(echo "$temp / 1000" | bc -l)"
            fi
        done
        echo
    fi

    # NVIDIA (nvidia-smi) → AMD (rocm-smi) → give up.
    printf "\n${bold}${magenta} GPU${reset}  "
    if command -v nvidia-smi &>/dev/null; then
        nvidia-smi --query-gpu=name,utilization.gpu,memory.used,memory.total,temperature.gpu \
            --format=csv,noheader,nounits | while IFS=',' read -r name util mem_used mem_total temp; do
            name="${name## }"; util="${util## }"; mem_used="${mem_used## }"
            mem_total="${mem_total## }"; temp="${temp## }"
            local vram_pct=$(( mem_used * 100 / mem_total ))
            printf "%s  ${magenta}%s°C${reset}\n" "$name" "$temp"
            printf "       Load %s%%  " "$util"; _bar "$util"; echo
            printf "       VRAM %sMiB / %sMiB  " "$mem_used" "$mem_total"; _bar "$vram_pct"; echo
        done
    elif command -v rocm-smi &>/dev/null; then
        rocm-smi --showuse --showtemp --showmemuse 2>/dev/null
    else
        echo "No GPU tools found"
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

    if command -v nvidia-smi &>/dev/null; then
        local driver gpu
        driver=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -1)
        gpu=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1)
        printf "  ${green}%-${label_w}s${reset} %s  ${dim}(%s)${reset}\n" "NVIDIA Driver" "$driver" "${gpu## }"
    fi

    if command -v nvcc &>/dev/null; then
        local cuda_ver
        cuda_ver=$(nvcc --version 2>/dev/null | grep -oP 'release \K[0-9.]+')
        printf "  ${green}%-${label_w}s${reset} %s\n" "CUDA Toolkit" "$cuda_ver"
    fi

    # ROS 2 if a workspace is sourced, or /opt/ros has a distro installed.
    local _ros_distro="${ROS_DISTRO:-}"
    if [[ -z "$_ros_distro" && -d /opt/ros ]]; then
        _ros_distro=$(ls /opt/ros/ 2>/dev/null | head -1)
    fi
    if [[ -n "$_ros_distro" ]]; then
        local ros_pkg_ver
        ros_pkg_ver=$(dpkg -l "ros-${_ros_distro}-ros-core" 2>/dev/null | awk '/^ii/{print $3}' | cut -d- -f1)
        if [[ -n "$ros_pkg_ver" ]]; then
            printf "  ${cyan}%-${label_w}s${reset} %s  ${dim}(%s)${reset}\n" "ROS 2" "$ros_pkg_ver" "$_ros_distro"
        else
            printf "  ${cyan}%-${label_w}s${reset} %s\n" "ROS 2" "$_ros_distro"
        fi
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

    if command -v docker &>/dev/null; then
        local docker_ver
        docker_ver=$(docker --version 2>/dev/null | grep -oP '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        printf "  ${yellow}%-${label_w}s${reset} %s\n" "Docker" "$docker_ver"
    fi

    echo
}

# Static hardware/OS summary (model, CPU, GPU, network, memory).
get-sys-info() {
    local bold='\033[1m' dim='\033[37m' reset='\033[0m'
    local cyan='\033[36m' green='\033[32m' yellow='\033[33m' magenta='\033[35m'
    local label_w=20

    printf "\n${bold}  System Information${reset}\n"
    printf "${dim}  ──────────────────────────────────────${reset}\n"

    local os_pretty
    if [[ -f /etc/os-release ]]; then
        os_pretty=$(. /etc/os-release && echo "$PRETTY_NAME")
    fi
    printf "  ${cyan}%-${label_w}s${reset} %s\n" "OS" "${os_pretty:-Unknown}"
    printf "  ${cyan}%-${label_w}s${reset} %s\n" "Kernel" "$(uname -r)"
    printf "  ${cyan}%-${label_w}s${reset} %s\n" "Architecture" "$(uname -m)"
    printf "  ${cyan}%-${label_w}s${reset} %s\n" "Hostname" "$(hostname)"

    # Prefer lscpu; fall back to /proc/cpuinfo.
    local cpu_model total_cores total_threads cpu_freq
    if command -v lscpu &>/dev/null; then
        cpu_model=$(lscpu | awk -F': +' '/^Model name/{print $2; exit}')
        local cpu_sockets cpu_cores cpu_threads_per_core
        cpu_sockets=$(lscpu | awk -F': +' '/^Socket\(s\)/{print $2}')
        cpu_cores=$(lscpu | awk -F': +' '/^Core\(s\) per socket/{print $2}')
        cpu_threads_per_core=$(lscpu | awk -F': +' '/^Thread\(s\) per core/{print $2}')
        total_cores=$(( ${cpu_sockets:-1} * ${cpu_cores:-1} ))
        total_threads=$(( total_cores * ${cpu_threads_per_core:-1} ))
        cpu_freq=$(lscpu | awk -F': +' '/^CPU max MHz/{printf "%.1f GHz", $2/1000; exit}')
    else
        cpu_model=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs)
        total_cores=$(grep -c '^processor' /proc/cpuinfo)
        total_threads=$total_cores
    fi
    printf "\n  ${green}%-${label_w}s${reset} %s\n" "CPU" "${cpu_model:-Unknown}"
    [[ -n "${total_cores:-}" ]] && \
        printf "  ${dim}%-${label_w}s${reset} %s cores / %s threads%s\n" \
            "" "$total_cores" "${total_threads:-$total_cores}" \
            "${cpu_freq:+  @ $cpu_freq}"

    # GPU: NVIDIA → AMD → sysfs / lspci fallback.
    if command -v nvidia-smi &>/dev/null; then
        local gpu_idx=0
        while IFS=',' read -r name vram driver; do
            name="${name## }"; vram="${vram## }"; driver="${driver## }"
            local label="GPU"
            [[ $gpu_idx -gt 0 ]] && label="GPU $gpu_idx"
            printf "\n  ${magenta}%-${label_w}s${reset} %s\n" "$label" "$name"
            printf "  ${dim}%-${label_w}s${reset} %s MiB VRAM  ${dim}(driver %s)${reset}\n" \
                "" "$vram" "$driver"
            (( gpu_idx++ ))
        done < <(nvidia-smi \
            --query-gpu=name,memory.total,driver_version \
            --format=csv,noheader,nounits 2>/dev/null)
    elif command -v rocm-smi &>/dev/null; then
        local gpu_name
        gpu_name=$(rocm-smi --showproductname 2>/dev/null | grep -oP 'Card series:\s+\K.+' | head -1)
        printf "\n  ${magenta}%-${label_w}s${reset} %s\n" "GPU" "${gpu_name:-AMD GPU (rocm-smi)}"
    else
        local gpu_name
        gpu_name=$(find /sys/class/drm/*/device -name 'label' 2>/dev/null | xargs cat 2>/dev/null | head -1)
        [[ -z "$gpu_name" ]] && gpu_name=$(lspci 2>/dev/null | grep -iE 'VGA|3D|Display' | head -1 | sed 's/.*: //')
        printf "\n  ${magenta}%-${label_w}s${reset} %s\n" "GPU" "${gpu_name:-Not detected}"
    fi

    # Interfaces with an IPv4 address. WiFi detected via /sys/.../wireless.
    printf "\n"
    local first_net=1
    while IFS= read -r line; do
        local iface ip type_label
        iface=$(awk '{print $1}' <<< "$line")
        ip=$(awk '{print $3}' <<< "$line" | cut -d/ -f1)
        [[ -z "$ip" || "$iface" == "lo" ]] && continue
        if [[ -d "/sys/class/net/$iface/wireless" ]]; then
            type_label="WiFi"
        else
            type_label="ETH"
        fi
        local label="Network"
        [[ $first_net -eq 0 ]] && label=""
        printf "  ${cyan}%-${label_w}s${reset} %-6s ${dim}%-12s${reset} %s\n" \
            "$label" "$type_label" "$iface" "$ip"
        first_net=0
    done < <(ip -br addr 2>/dev/null | awk '$3 != ""')

    local gw_ip gw_iface
    read -r gw_ip gw_iface < <(ip route show default 2>/dev/null \
        | awk '/^default/ {print $3, $5; exit}')
    if [[ -n "$gw_ip" ]]; then
        printf "  ${dim}%-${label_w}s Gateway %-15s via %s${reset}\n" "" "$gw_ip" "$gw_iface"
    fi

    # DIMM type/speed needs dmidecode (often root) — best-effort.
    local mem_total mem_type mem_speed
    mem_total=$(awk '/^MemTotal/ {printf "%.1f GiB", $2/1024/1024}' /proc/meminfo)
    if command -v dmidecode &>/dev/null && dmidecode -t memory &>/dev/null 2>&1; then
        mem_type=$(dmidecode -t memory 2>/dev/null | awk '/^\s+Type:/ && !/Unknown/ {print $2; exit}')
        mem_speed=$(dmidecode -t memory 2>/dev/null | awk '/^\s+Speed:.*MT/ {print $2" "$3; exit}')
    fi
    printf "\n  ${yellow}%-${label_w}s${reset} %s%s\n" "Memory" "$mem_total" \
        "${mem_type:+  ${dim}($mem_type${mem_speed:+ @ $mem_speed})${reset}}"

    local sys_mfr sys_product
    if [[ -r /sys/class/dmi/id/sys_vendor ]]; then
        sys_mfr=$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null)
        sys_product=$(cat /sys/class/dmi/id/product_name 2>/dev/null)
    fi
    if [[ -n "$sys_mfr" && "$sys_mfr" != "To Be Filled By O.E.M." ]]; then
        printf "  ${yellow}%-${label_w}s${reset} %s %s\n" "Board" "$sys_mfr" "$sys_product"
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

    ps -eo rss=,%cpu=,comm= --no-headers --sort=-rss \
        | head -n "$n" \
        | while read -r rss cpu comm; do
            [[ -z "$rss" || "$rss" -eq 0 ]] && continue
            local ram
            if (( rss >= 1048576 )); then
                ram=$(awk "BEGIN {printf \"%.1f GiB\", $rss/1048576}")
            elif (( rss >= 1024 )); then
                ram=$(awk "BEGIN {printf \"%.0f MiB\", $rss/1024}")
            else
                ram="${rss} KiB"
            fi
            printf "  ${cyan}%-24s${reset} %10s %6s%%\n" "$comm" "$ram" "$cpu"
        done
    echo
}
