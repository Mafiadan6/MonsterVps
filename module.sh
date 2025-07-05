#!/bin/bash

# MonsterVps Module System - mastermind
# Core module functions for MonsterVps system

# Colors
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[1;33m'
blue='\033[0;34m'
cyan='\033[0;36m'
purple='\033[0;35m'
rest='\033[0m'

# Message functions
msg() {
    case $1 in
        -bar)
            echo -e "${cyan}================================================================${rest}"
            ;;
        -bar1)
            echo -e "${yellow}================================================================${rest}"
            ;;
        -bar2)
            echo -e "${green}================================================================${rest}"
            ;;
        -bar3)
            echo -e "${red}================================================================${rest}"
            ;;
        -ne)
            echo -ne "${2}"
            ;;
        *)
            echo -e "${1}"
            ;;
    esac
}

# Print center function
print_center() {
    local text="$2"
    local color=""
    
    case $1 in
        -ama) color="${yellow}" ;;
        -verm) color="${red}" ;;
        -verd) color="${green}" ;;
        -azul) color="${blue}" ;;
        -cyan) color="${cyan}" ;;
        *) color="${rest}" ;;
    esac
    
    local term_width=$(tput cols 2>/dev/null || echo 80)
    local text_length=${#text}
    local padding=$(( (term_width - text_length) / 2 ))
    
    printf "%*s%s%s%s\n" $padding "" "$color" "$text" "$rest"
}

# Title function
title() {
    clear
    msg -bar
    print_center -ama "$1"
    msg -bar
}

# Enter function
enter() {
    msg -bar
    read -p "Press Enter to continue..."
    msg -bar
}

# Loading function
loading() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    echo -ne "${yellow}"
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf "\r[%c] " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
    done
    printf "\r"
    echo -ne "${rest}"
}

# Progress bar function
progress_bar() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    printf "\r${cyan}["
    printf "%*s" $filled | tr ' ' '='
    printf "%*s" $empty | tr ' ' '-'
    printf "] %d%% (%d/%d)${rest}" $percentage $current $total
}

# Selection menu function
selection_fun() {
    local options=("$@")
    local num_options=${#options[@]}
    
    msg -bar
    for i in "${!options[@]}"; do
        printf " ${green}%2d)${rest} %s\n" $((i+1)) "${options[$i]}"
    done
    msg -bar
    
    while true; do
        read -p "Select option [1-$num_options]: " selection
        if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "$num_options" ]; then
            return $((selection-1))
        else
            echo -e "${red}Invalid option. Please try again.${rest}"
        fi
    done
}

# IP validation function
valid_ip() {
    local ip=$1
    local stat=1
    
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    
    return $stat
}

# Check service function
check_service() {
    local service=$1
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Install package function
install_package() {
    local package=$1
    echo -e "${yellow}Installing $package...${rest}"
    
    if command -v apt-get &> /dev/null; then
        apt-get update -qq
        apt-get install -y "$package"
    elif command -v yum &> /dev/null; then
        yum install -y "$package"
    elif command -v dnf &> /dev/null; then
        dnf install -y "$package"
    else
        echo -e "${red}Package manager not found${rest}"
        return 1
    fi
}

# System info function
system_info() {
    echo -e "${cyan}System Information:${rest}"
    echo -e "OS: $(lsb_release -d 2>/dev/null | cut -f2 || uname -a)"
    echo -e "Kernel: $(uname -r)"
    echo -e "Architecture: $(uname -m)"
    echo -e "Memory: $(free -h | awk '/^Mem:/ {print $3"/"$2}')"
    echo -e "Disk: $(df -h / | awk 'NR==2 {print $3"/"$2" ("$5" used)"}')"
    echo -e "CPU: $(nproc) cores"
    echo -e "Load: $(uptime | awk -F'load average:' '{print $2}')"
}

# Network info function
network_info() {
    echo -e "${cyan}Network Information:${rest}"
    
    # Get primary IP
    local ip=$(curl -s ipv4.icanhazip.com 2>/dev/null || wget -qO- ipv4.icanhazip.com 2>/dev/null || echo "Unknown")
    echo -e "Public IP: $ip"
    
    # Get local IP
    local local_ip=$(ip route get 8.8.8.8 2>/dev/null | awk 'NR==1 {print $7}' || echo "Unknown")
    echo -e "Local IP: $local_ip"
    
    # Get hostname
    echo -e "Hostname: $(hostname)"
    
    # Get DNS
    echo -e "DNS: $(cat /etc/resolv.conf | grep nameserver | head -1 | awk '{print $2}' || echo "Unknown")"
}

# Banner function
banner() {
    clear
    echo -e "${cyan}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                        MonsterVps                            ║"
    echo "║                  Advanced VPN Manager                        ║"
    echo "║                     by mastermind                           ║"
    echo "║                                                              ║"
    echo "║    Comprehensive Multi-Protocol VPN & Proxy Management      ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${rest}"
}

# Error handling function
error_exit() {
    echo -e "${red}Error: $1${rest}" >&2
    exit 1
}

# Success message function
success_msg() {
    echo -e "${green}✓ $1${rest}"
}

# Warning message function
warning_msg() {
    echo -e "${yellow}⚠ $1${rest}"
}

# Info message function
info_msg() {
    echo -e "${blue}ℹ $1${rest}"
}

# Debug message function
debug_msg() {
    if [[ "$DEBUG" == "true" ]]; then
        echo -e "${purple}[DEBUG] $1${rest}"
    fi
}

# Log function
log_msg() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_file="/var/log/monstervps.log"
    
    echo "[$timestamp] [$level] $message" >> "$log_file" 2>/dev/null
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error_exit "This script must be run as root"
    fi
}

# Check internet connection
check_internet() {
    if ! ping -c 1 google.com &> /dev/null; then
        error_exit "No internet connection available"
    fi
}

# Get OS version
get_os_version() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "$VERSION_ID"
    else
        echo "unknown"
    fi
}

# Update repositories function
update_repos() {
    echo -e "${yellow}Updating package repositories...${rest}"
    
    if command -v apt-get &> /dev/null; then
        apt-get update -qq
    elif command -v yum &> /dev/null; then
        yum update -y
    elif command -v dnf &> /dev/null; then
        dnf update -y
    fi
}

# Install dependencies function
install_dependencies() {
    local deps=("curl" "wget" "unzip" "jq" "bc" "netstat" "lsof" "htop" "nano" "screen")
    
    echo -e "${yellow}Installing dependencies...${rest}"
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            install_package "$dep"
        fi
    done
}

# Cleanup function
cleanup() {
    local temp_files=("/tmp/monstervps_*" "/tmp/install_*")
    
    for pattern in "${temp_files[@]}"; do
        rm -rf $pattern 2>/dev/null
    done
}

# Configuration save function
save_config() {
    local config_file="/etc/MonsterVps/config/main.conf"
    local key="$1"
    local value="$2"
    
    mkdir -p "$(dirname "$config_file")"
    
    if grep -q "^$key=" "$config_file" 2>/dev/null; then
        sed -i "s/^$key=.*/$key=$value/" "$config_file"
    else
        echo "$key=$value" >> "$config_file"
    fi
}

# Configuration load function
load_config() {
    local config_file="/etc/MonsterVps/config/main.conf"
    local key="$1"
    
    if [[ -f "$config_file" ]]; then
        grep "^$key=" "$config_file" | cut -d'=' -f2
    fi
}

# Service management functions
start_service() {
    local service="$1"
    systemctl start "$service" 2>/dev/null && success_msg "Started $service" || warning_msg "Failed to start $service"
}

stop_service() {
    local service="$1"
    systemctl stop "$service" 2>/dev/null && success_msg "Stopped $service" || warning_msg "Failed to stop $service"
}

enable_service() {
    local service="$1"
    systemctl enable "$service" 2>/dev/null && success_msg "Enabled $service" || warning_msg "Failed to enable $service"
}

# Export all functions
export -f msg print_center title enter loading progress_bar selection_fun valid_ip check_service
export -f install_package system_info network_info banner error_exit success_msg warning_msg
export -f info_msg debug_msg log_msg check_root check_internet get_os_version update_repos
export -f install_dependencies cleanup save_config load_config start_service stop_service enable_service