#!/bin/bash

# MonsterVps Main Menu System - mastermind
# Central interface for all VPN and proxy management tools

# Colors
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[1;33m'
blue='\033[0;34m'
cyan='\033[0;36m'
purple='\033[0;35m'
rest='\033[0m'

# System paths
MONSTERVPS_DIR="/etc/MonsterVps"
UTILS_DIR="$(pwd)/Utils"
ONLINE_DIR="$(pwd)/online"
LOG_FILE="/var/log/monstervps.log"

# Create necessary directories
mkdir -p "$MONSTERVPS_DIR/db" "$MONSTERVPS_DIR/config" "$MONSTERVPS_DIR/logs" 2>/dev/null

# Banner function
show_banner() {
    clear
    echo -e "${cyan}╔══════════════════════════════════════════════════════════════╗${rest}"
    echo -e "${cyan}║                        MonsterVps                            ║${rest}"
    echo -e "${cyan}║                  Advanced VPN Manager                        ║${rest}"
    echo -e "${cyan}║                     by mastermind                           ║${rest}"
    echo -e "${cyan}║                                                              ║${rest}"
    echo -e "${cyan}║    Comprehensive Multi-Protocol VPN & Proxy Management      ║${rest}"
    echo -e "${cyan}╚══════════════════════════════════════════════════════════════╝${rest}"
    echo ""
}

# System information
show_system_info() {
    echo -e "${blue}System Information:${rest}"
    echo -e "  Hostname: $(hostname)"
    echo -e "  OS: $(uname -s) $(uname -r)"
    echo -e "  Uptime: $(uptime | awk '{print $3,$4}' | sed 's/,//')"
    echo -e "  Load: $(uptime | awk -F'load average:' '{print $2}')"
    echo -e "  Memory: $(free -h | awk '/^Mem:/ {print $3"/"$2}')"
    echo -e "  Disk: $(df -h / | awk 'NR==2 {print $3"/"$2" ("$5" used)"}')"
    echo ""
}

# Service status check
check_service_status() {
    local service="$1"
    local port="$2"
    
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        echo -e "${green}✓ $service${rest}"
    else
        if netstat -tlnp 2>/dev/null | grep -q ":$port "; then
            echo -e "${yellow}⚠ $service (custom)${rest}"
        else
            echo -e "${red}✗ $service${rest}"
        fi
    fi
}

# Show service status
show_service_status() {
    echo -e "${blue}Service Status:${rest}"
    check_service_status "ssh" "22"
    check_service_status "v2ray" "443"
    check_service_status "openvpn" "1194"
    check_service_status "wg-quick@wg0" "51820"
    check_service_status "stunnel4" "443"
    check_service_status "dropbear" "443"
    echo ""
}

# User management menu
user_management_menu() {
    while true; do
        show_banner
        echo -e "${green}=== User Management ===${rest}"
        echo ""
        echo -e "${green}1)${rest} SSH User Management"
        echo -e "${green}2)${rest} V2Ray User Management"
        echo -e "${green}3)${rest} WireGuard User Management"
        echo -e "${green}4)${rest} OpenVPN User Management"
        echo -e "${green}5)${rest} Database Manager"
        echo -e "${green}6)${rest} User Monitor System"
        echo -e "${green}7)${rest} Connection Limiter"
        echo -e "${green}8)${rest} User Activity Report"
        echo -e "${green}0)${rest} Back to Main Menu"
        echo ""
        read -p "Select option: " option
        
        case $option in
            1)
                if [[ -f "$UTILS_DIR/user-managers/install.sh" ]]; then
                    $UTILS_DIR/user-managers/install.sh
                else
                    echo -e "${yellow}SSH user manager not found. Using database manager...${rest}"
                    $UTILS_DIR/database-manager.sh
                fi
                ;;
            2)
                if [[ -f "$UTILS_DIR/v2ray/menu.sh" ]]; then
                    $UTILS_DIR/v2ray/menu.sh
                else
                    echo -e "${yellow}V2Ray manager not found. Using database manager...${rest}"
                    $UTILS_DIR/database-manager.sh
                fi
                ;;
            3)
                echo -e "${yellow}Opening WireGuard user management...${rest}"
                $UTILS_DIR/database-manager.sh
                ;;
            4)
                echo -e "${yellow}Opening OpenVPN user management...${rest}"
                $UTILS_DIR/database-manager.sh
                ;;
            5)
                $UTILS_DIR/database-manager.sh
                ;;
            6)
                $UTILS_DIR/user-monitor.sh
                ;;
            7)
                $UTILS_DIR/limitador.sh
                ;;
            8)
                echo -e "${yellow}Generating user activity report...${rest}"
                $UTILS_DIR/user-monitor.sh report
                read -p "Press Enter to continue..."
                ;;
            0)
                break
                ;;
            *)
                echo -e "${red}Invalid option${rest}"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Protocol management menu
protocol_management_menu() {
    while true; do
        show_banner
        echo -e "${green}=== Protocol Management ===${rest}"
        echo ""
        echo -e "${green}1)${rest} SSH & Dropbear Configuration"
        echo -e "${green}2)${rest} V2Ray Protocol Setup"
        echo -e "${green}3)${rest} WireGuard Configuration"
        echo -e "${green}4)${rest} OpenVPN Setup"
        echo -e "${green}5)${rest} Stunnel SSL Tunnel"
        echo -e "${green}6)${rest} SlowDNS Configuration"
        echo -e "${green}7)${rest} UDP Protocols Menu"
        echo -e "${green}8)${rest} SOCKS Python Proxy"
        echo -e "${green}9)${rest} Psiphon Protocol"
        echo -e "${green}10)${rest} BadVPN UDP Gateway"
        echo -e "${green}0)${rest} Back to Main Menu"
        echo ""
        read -p "Select option: " option
        
        case $option in
            1)
                if [[ -f "$UTILS_DIR/dropBear/install.sh" ]]; then
                    $UTILS_DIR/dropBear/install.sh
                else
                    echo -e "${yellow}SSH/Dropbear manager not available${rest}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            2)
                if [[ -f "$UTILS_DIR/v2ray/install.sh" ]]; then
                    $UTILS_DIR/v2ray/install.sh
                else
                    echo -e "${yellow}V2Ray installer not available${rest}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            3)
                echo -e "${yellow}WireGuard configuration coming soon...${rest}"
                read -p "Press Enter to continue..."
                ;;
            4)
                echo -e "${yellow}OpenVPN setup coming soon...${rest}"
                read -p "Press Enter to continue..."
                ;;
            5)
                if [[ -f "$UTILS_DIR/Stunnel/install.sh" ]]; then
                    $UTILS_DIR/Stunnel/install.sh
                else
                    echo -e "${yellow}Stunnel installer not available${rest}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            6)
                if [[ -f "$UTILS_DIR/SlowDNS/install.sh" ]]; then
                    $UTILS_DIR/SlowDNS/install.sh
                else
                    echo -e "${yellow}SlowDNS installer not available${rest}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            7)
                if [[ -f "$UTILS_DIR/protocolsUDP/menu.sh" ]]; then
                    $UTILS_DIR/protocolsUDP/menu.sh
                else
                    echo -e "${yellow}UDP protocols menu not available${rest}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            8)
                if [[ -f "$UTILS_DIR/socksPY/menu.sh" ]]; then
                    $UTILS_DIR/socksPY/menu.sh
                else
                    echo -e "${yellow}SOCKS Python menu not available${rest}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            9)
                if [[ -f "$UTILS_DIR/psiphon/install.sh" ]]; then
                    $UTILS_DIR/psiphon/install.sh
                else
                    echo -e "${yellow}Psiphon installer not available${rest}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            10)
                if [[ -f "$UTILS_DIR/badvpn/install.sh" ]]; then
                    $UTILS_DIR/badvpn/install.sh
                else
                    echo -e "${yellow}BadVPN installer not available${rest}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            0)
                break
                ;;
            *)
                echo -e "${red}Invalid option${rest}"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# System tools menu
system_tools_menu() {
    while true; do
        show_banner
        echo -e "${green}=== System Tools ===${rest}"
        echo ""
        echo -e "${green}1)${rest} Port Management"
        echo -e "${green}2)${rest} Firewall Configuration"
        echo -e "${green}3)${rest} System Monitor"
        echo -e "${green}4)${rest} Speed Test"
        echo -e "${green}5)${rest} Certificate Generator"
        echo -e "${green}6)${rest} Clear System Logs"
        echo -e "${green}7)${rest} Timezone Configuration"
        echo -e "${green}8)${rest} Fail2Ban Security"
        echo -e "${green}9)${rest} DNS Configuration"
        echo -e "${green}10)${rest} Apache Configuration"
        echo -e "${green}11)${rest} SSL Certificate Manager"
        echo -e "${green}12)${rest} System Backup"
        echo -e "${green}0)${rest} Back to Main Menu"
        echo ""
        read -p "Select option: " option
        
        case $option in
            1)
                if [[ -f "$ONLINE_DIR/ports.sh" ]]; then
                    $ONLINE_DIR/ports.sh
                else
                    if [[ -f "$UTILS_DIR/mine_port/install.sh" ]]; then
                        $UTILS_DIR/mine_port/install.sh
                    else
                        echo -e "${yellow}Port management tools not available${rest}"
                        read -p "Press Enter to continue..."
                    fi
                fi
                ;;
            2)
                if [[ -f "$ONLINE_DIR/firewall-VPS.sh" ]]; then
                    $ONLINE_DIR/firewall-VPS.sh
                else
                    echo -e "${yellow}Firewall configuration not available${rest}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            3)
                if [[ -f "$ONLINE_DIR/monitor_htop.sh" ]]; then
                    $ONLINE_DIR/monitor_htop.sh
                else
                    htop 2>/dev/null || top
                fi
                ;;
            4)
                if [[ -f "$ONLINE_DIR/speed.sh" ]]; then
                    $ONLINE_DIR/speed.sh
                elif [[ -f "$ONLINE_DIR/speedtest.py" ]]; then
                    python3 $ONLINE_DIR/speedtest.py
                else
                    echo -e "${yellow}Speed test tools not available${rest}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            5)
                if [[ -f "$UTILS_DIR/genCert/install.sh" ]]; then
                    $UTILS_DIR/genCert/install.sh
                else
                    echo -e "${yellow}Certificate generator not available${rest}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            6)
                if [[ -f "$ONLINE_DIR/clearLog.sh" ]]; then
                    $ONLINE_DIR/clearLog.sh
                else
                    echo -e "${yellow}Clearing system logs...${rest}"
                    journalctl --vacuum-time=1d 2>/dev/null
                    echo -e "${green}System logs cleared${rest}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            7)
                if [[ -f "$ONLINE_DIR/timeZone.sh" ]]; then
                    $ONLINE_DIR/timeZone.sh
                else
                    echo -e "${yellow}Timezone configuration not available${rest}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            8)
                if [[ -f "$ONLINE_DIR/fail2ban.sh" ]]; then
                    $ONLINE_DIR/fail2ban.sh
                else
                    echo -e "${yellow}Fail2Ban configuration not available${rest}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            9)
                if [[ -f "$ONLINE_DIR/dns-netflix.sh" ]]; then
                    $ONLINE_DIR/dns-netflix.sh
                else
                    echo -e "${yellow}DNS configuration not available${rest}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            10)
                if [[ -f "$ONLINE_DIR/apacheon.sh" ]]; then
                    $ONLINE_DIR/apacheon.sh
                else
                    echo -e "${yellow}Apache configuration not available${rest}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            11)
                if [[ -f "$ONLINE_DIR/ssl.sh" ]]; then
                    $ONLINE_DIR/ssl.sh
                else
                    echo -e "${yellow}SSL certificate manager not available${rest}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            12)
                $UTILS_DIR/database-manager.sh backup
                read -p "Press Enter to continue..."
                ;;
            0)
                break
                ;;
            *)
                echo -e "${red}Invalid option${rest}"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Advanced tools menu
advanced_tools_menu() {
    while true; do
        show_banner
        echo -e "${green}=== Advanced Tools ===${rest}"
        echo ""
        echo -e "${green}1)${rest} Auto-Start Services Manager"
        echo -e "${green}2)${rest} Auto-Update System"
        echo -e "${green}3)${rest} Token Authentication (aToken)"
        echo -e "${green}4)${rest} System Banner Configuration"
        echo -e "${green}5)${rest} User Activity Checker"
        echo -e "${green}6)${rest} E-Pro WebSocket"
        echo -e "${green}7)${rest} UDP Custom Protocol"
        echo -e "${green}8)${rest} UDP ZiVPN Protocol"
        echo -e "${green}9)${rest} SQLite Database Manager"
        echo -e "${green}10)${rest} Telegram Bot (ADMbot)"
        echo -e "${green}11)${rest} Payment System"
        echo -e "${green}12)${rest} Block BitTorrent"
        echo -e "${green}0)${rest} Back to Main Menu"
        echo ""
        read -p "Select option: " option
        
        case $option in
            1)
                if [[ -f "$UTILS_DIR/autoStart/install.sh" ]]; then
                    $UTILS_DIR/autoStart/install.sh
                else
                    echo -e "${yellow}Auto-start manager not available${rest}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            2)
                if [[ -f "$UTILS_DIR/auto-update/install.sh" ]]; then
                    $UTILS_DIR/auto-update/install.sh
                else
                    echo -e "${yellow}Auto-update system not available${rest}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            3)
                if [[ -f "$UTILS_DIR/aToken/install.sh" ]]; then
                    $UTILS_DIR/aToken/install.sh
                else
                    echo -e "${yellow}aToken system not available${rest}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            4)
                if [[ -f "$UTILS_DIR/banner/install.sh" ]]; then
                    $UTILS_DIR/banner/install.sh
                else
                    echo -e "${yellow}Banner configuration not available${rest}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            5)
                if [[ -f "$UTILS_DIR/checkuser/install.sh" ]]; then
                    $UTILS_DIR/checkuser/install.sh
                else
                    echo -e "${yellow}User checker not available${rest}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            6)
                if [[ -f "$UTILS_DIR/epro-ws/install.sh" ]]; then
                    $UTILS_DIR/epro-ws/install.sh
                else
                    echo -e "${yellow}E-Pro WebSocket not available${rest}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            7)
                if [[ -f "$UTILS_DIR/udp-custom/install.sh" ]]; then
                    $UTILS_DIR/udp-custom/install.sh
                else
                    echo -e "${yellow}UDP Custom not available${rest}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            8)
                if [[ -f "$UTILS_DIR/udp-zivpn/install.sh" ]]; then
                    $UTILS_DIR/udp-zivpn/install.sh
                else
                    echo -e "${yellow}UDP ZiVPN not available${rest}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            9)
                if [[ -f "$UTILS_DIR/Csqlite/install.sh" ]]; then
                    $UTILS_DIR/Csqlite/install.sh
                else
                    echo -e "${yellow}SQLite manager not available${rest}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            10)
                if [[ -f "$ONLINE_DIR/ADMbot.sh" ]]; then
                    $ONLINE_DIR/ADMbot.sh
                else
                    echo -e "${yellow}Telegram bot not available${rest}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            11)
                if [[ -f "$ONLINE_DIR/paysnd.sh" ]]; then
                    $ONLINE_DIR/paysnd.sh
                else
                    echo -e "${yellow}Payment system not available${rest}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            12)
                if [[ -f "$ONLINE_DIR/blockBT.sh" ]]; then
                    $ONLINE_DIR/blockBT.sh
                else
                    echo -e "${yellow}BitTorrent blocker not available${rest}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            0)
                break
                ;;
            *)
                echo -e "${red}Invalid option${rest}"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Information and about menu
info_menu() {
    show_banner
    echo -e "${green}=== MonsterVps Information ===${rest}"
    echo ""
    echo -e "${cyan}Version:${rest} $(cat vercion 2>/dev/null || echo "1.0.0")"
    echo -e "${cyan}Developer:${rest} mastermind"
    echo -e "${cyan}Based on:${rest} ADMRufu (completely rebranded)"
    echo -e "${cyan}License:${rest} Open Source"
    echo ""
    echo -e "${blue}Features:${rest}"
    echo -e "  • Multi-protocol VPN support (SSH, V2Ray, WireGuard, OpenVPN)"
    echo -e "  • Advanced user management with connection limits"
    echo -e "  • Real-time monitoring and statistics"
    echo -e "  • Automated connection limiting"
    echo -e "  • Token-based authentication system"
    echo -e "  • Comprehensive database management"
    echo -e "  • Multiple tunnel protocols (Stunnel, SlowDNS, UDP)"
    echo -e "  • System optimization tools"
    echo -e "  • Security features (Fail2Ban, Firewall)"
    echo ""
    echo -e "${blue}Supported Protocols:${rest}"
    echo -e "  • SSH/Dropbear • V2Ray/VMess • WireGuard • OpenVPN"
    echo -e "  • Stunnel SSL • SlowDNS • UDP Custom • SOCKS Proxy"
    echo -e "  • Psiphon • BadVPN • E-Pro WebSocket"
    echo ""
    echo -e "${blue}System Status:${rest}"
    show_service_status
    echo ""
    read -p "Press Enter to continue..."
}

# Main menu
main_menu() {
    while true; do
        show_banner
        show_system_info
        show_service_status
        echo -e "${green}Main Menu:${rest}"
        echo ""
        echo -e "${green}1)${rest} User Management"
        echo -e "${green}2)${rest} Protocol Management"
        echo -e "${green}3)${rest} System Tools"
        echo -e "${green}4)${rest} Advanced Tools"
        echo -e "${green}5)${rest} Information & About"
        echo -e "${green}6)${rest} Run System Tests"
        echo -e "${green}7)${rest} Update MonsterVps"
        echo -e "${green}8)${rest} Uninstall MonsterVps"
        echo -e "${green}0)${rest} Exit"
        echo ""
        read -p "Select option: " option
        
        case $option in
            1)
                user_management_menu
                ;;
            2)
                protocol_management_menu
                ;;
            3)
                system_tools_menu
                ;;
            4)
                advanced_tools_menu
                ;;
            5)
                info_menu
                ;;
            6)
                if [[ -f "test_menu.sh" ]]; then
                    ./test_menu.sh
                else
                    echo -e "${yellow}Running quick system test...${rest}"
                    echo "Utils components: $(ls Utils/ | wc -l)"
                    echo "Online scripts: $(ls online/ | wc -l)"
                    echo "Services status: $(systemctl list-units --failed | wc -l) failed"
                    read -p "Press Enter to continue..."
                fi
                ;;
            7)
                echo -e "${yellow}Checking for MonsterVps updates...${rest}"
                if [[ -f "install.sh" ]]; then
                    ./install.sh --update
                else
                    echo -e "${red}Update script not found${rest}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            8)
                echo -e "${red}Are you sure you want to uninstall MonsterVps? (y/N)${rest}"
                read -r confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    if [[ -f "uninstall" ]]; then
                        ./uninstall
                    else
                        echo -e "${yellow}Uninstall script not found${rest}"
                    fi
                fi
                ;;
            0)
                echo -e "${green}Thank you for using MonsterVps!${rest}"
                echo -e "${cyan}System will continue running in background.${rest}"
                exit 0
                ;;
            *)
                echo -e "${red}Invalid option${rest}"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${red}MonsterVps must be run as root${rest}"
    echo -e "${yellow}Please run: sudo $0${rest}"
    exit 1
fi

# Initialize log file
touch "$LOG_FILE" 2>/dev/null

# Start main menu
main_menu