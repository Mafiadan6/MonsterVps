#!/bin/bash

# MonsterVps Connection Limiter - mastermind
# Advanced connection limiting and monitoring system

# Colors for output
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[1;33m'
blue='\033[0;34m'
cyan='\033[0;36m'
rest='\033[0m'

# Configuration
LIMIT_CONFIG="/etc/MonsterVps/limit.conf"
LOG_FILE="/var/log/monstervps_limiter.log"
PID_FILE="/var/run/monstervps_limiter.pid"

# Default settings
SSH_DEFAULT_LIMIT=2
V2RAY_DEFAULT_LIMIT=5
WIREGUARD_DEFAULT_LIMIT=3
CHECK_INTERVAL=30
ACTION_ON_EXCEED="kill"
EMAIL_NOTIFICATIONS="false"
EMAIL_TO=""
WHITELIST_USERS="root,admin"

# Load configuration
load_config() {
    if [[ -f "$LIMIT_CONFIG" ]]; then
        source "$LIMIT_CONFIG"
    else
        save_config
    fi
}

# Save configuration
save_config() {
    cat > "$LIMIT_CONFIG" << EOF
# MonsterVps Connection Limiter Configuration
SSH_DEFAULT_LIMIT=$SSH_DEFAULT_LIMIT
V2RAY_DEFAULT_LIMIT=$V2RAY_DEFAULT_LIMIT
WIREGUARD_DEFAULT_LIMIT=$WIREGUARD_DEFAULT_LIMIT
CHECK_INTERVAL=$CHECK_INTERVAL
ACTION_ON_EXCEED=$ACTION_ON_EXCEED
EMAIL_NOTIFICATIONS=$EMAIL_NOTIFICATIONS
EMAIL_TO=$EMAIL_TO
WHITELIST_USERS=$WHITELIST_USERS
EOF
}

# Logging function
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    # Also show on screen if running interactively
    if [[ -t 1 ]]; then
        case $level in
            "ERROR") echo -e "${red}[$timestamp] [$level] $message${rest}" ;;
            "WARN") echo -e "${yellow}[$timestamp] [$level] $message${rest}" ;;
            "INFO") echo -e "${green}[$timestamp] [$level] $message${rest}" ;;
            "DEBUG") echo -e "${blue}[$timestamp] [$level] $message${rest}" ;;
        esac
    fi
}

# Send notification
send_notification() {
    local message="$1"
    
    # Log the notification
    log_message "INFO" "Notification: $message"
    
    # Send email if configured
    if [[ "$EMAIL_NOTIFICATIONS" == "true" ]] && command -v mail &>/dev/null; then
        echo "$message" | mail -s "MonsterVps Limiter Alert" "$EMAIL_TO" 2>/dev/null
    fi
}

# Check SSH connection limits
check_ssh_limits() {
    log_message "DEBUG" "Checking SSH connection limits"
    
    # Get all SSH users
    who | while read line; do
        local user=$(echo "$line" | awk '{print $1}')
        local terminal=$(echo "$line" | awk '{print $2}')
        
        # Skip if user is in whitelist
        if echo "$WHITELIST_USERS" | grep -q "$user"; then
            continue
        fi
        
        # Count connections for this user
        local connections=$(ps aux | grep -v grep | grep "sshd.*$user" | wc -l)
        
        # Get user-specific limit or use default
        local user_limit=$(sqlite3 "/etc/MonsterVps/db/users.db" "SELECT connection_limit FROM ssh_users WHERE username='$user';" 2>/dev/null || echo "$SSH_DEFAULT_LIMIT")
        
        if [[ $connections -gt $user_limit ]]; then
            log_message "WARN" "User $user exceeded SSH limit: $connections/$user_limit"
            send_notification "User $user exceeded SSH connection limit ($connections/$user_limit)"
            
            case "$ACTION_ON_EXCEED" in
                "kill")
                    # Kill excess connections
                    local pids=$(ps aux | grep -v grep | grep "sshd.*$user" | awk '{print $2}' | tail -n +$((user_limit + 1)))
                    for pid in $pids; do
                        kill -9 "$pid" 2>/dev/null
                        log_message "INFO" "Killed SSH connection PID $pid for user $user"
                    done
                    ;;
                "disable")
                    # Disable user temporarily
                    usermod -L "$user" 2>/dev/null
                    log_message "INFO" "Disabled user $user for exceeding limits"
                    ;;
            esac
        fi
    done
}

# Check V2Ray connection limits
check_v2ray_limits() {
    log_message "DEBUG" "Checking V2Ray connection limits"
    
    if [[ ! -f /var/log/v2ray/access.log ]]; then
        return
    fi
    
    # Get active V2Ray connections from log
    local current_time=$(date +%s)
    local cutoff_time=$((current_time - 300)) # 5 minutes ago
    
    # Parse V2Ray logs for active connections
    awk -v cutoff="$cutoff_time" '
    {
        # Extract timestamp and user from V2Ray log format
        # This is a simplified parser - adjust based on actual log format
        if (match($0, /email: ([^,]+)/, user)) {
            users[user[1]]++
        }
    }
    END {
        for (user in users) {
            if (users[user] > 0) {
                print user, users[user]
            }
        }
    }' /var/log/v2ray/access.log | while read user_email connections; do
        local user_limit=$(sqlite3 "/etc/MonsterVps/db/v2ray_users.db" "SELECT connection_limit FROM v2ray_users WHERE email='$user_email';" 2>/dev/null || echo "$V2RAY_DEFAULT_LIMIT")
        
        if [[ $connections -gt $user_limit ]]; then
            log_message "WARN" "V2Ray user $user_email exceeded limit: $connections/$user_limit"
            send_notification "V2Ray user $user_email exceeded connection limit ($connections/$user_limit)"
            
            # For V2Ray, we would need to implement connection dropping through V2Ray API
            # This is a placeholder for more advanced V2Ray management
        fi
    done
}

# Check WireGuard connection limits
check_wireguard_limits() {
    log_message "DEBUG" "Checking WireGuard connection limits"
    
    if ! command -v wg &> /dev/null; then
        return
    fi
    
    # Get WireGuard interface status
    wg show all latest-handshakes 2>/dev/null | while read interface public_key handshake_time; do
        local current_time=$(date +%s)
        local time_diff=$((current_time - handshake_time))
        
        # Consider connection active if handshake within last 3 minutes
        if [[ $time_diff -lt 180 ]]; then
            local username=$(sqlite3 "/etc/MonsterVps/db/wireguard_users.db" "SELECT username FROM wg_users WHERE public_key='$public_key';" 2>/dev/null)
            
            if [[ -n "$username" ]]; then
                # Count active connections for this user
                local user_connections=$(wg show all latest-handshakes 2>/dev/null | awk -v user="$username" -v current="$current_time" '
                {
                    if (current - $3 < 180) {
                        # Get username for this key
                        cmd = "sqlite3 \"/etc/MonsterVps/db/wireguard_users.db\" \"SELECT username FROM wg_users WHERE public_key='"'"'"$2"'"'"';\""
                        cmd | getline check_user
                        close(cmd)
                        if (check_user == user) count++
                    }
                }
                END { print count+0 }')
                
                local user_limit=$(sqlite3 "/etc/MonsterVps/db/wireguard_users.db" "SELECT connection_limit FROM wg_users WHERE username='$username';" 2>/dev/null || echo "$WIREGUARD_DEFAULT_LIMIT")
                
                if [[ $user_connections -gt $user_limit ]]; then
                    log_message "WARN" "WireGuard user $username exceeded limit: $user_connections/$user_limit"
                    send_notification "WireGuard user $username exceeded connection limit ($user_connections/$user_limit)"
                    
                    # Remove peer from WireGuard interface
                    wg set "$interface" peer "$public_key" remove 2>/dev/null
                    log_message "INFO" "Removed WireGuard peer $public_key for user $username"
                fi
            fi
        fi
    done
}

# Main monitoring loop
monitor_connections() {
    log_message "INFO" "Starting MonsterVps connection limiter (PID: $$)"
    echo $$ > "$PID_FILE"
    
    while true; do
        check_ssh_limits
        check_v2ray_limits
        check_wireguard_limits
        
        sleep "$CHECK_INTERVAL"
    done
}

# Start limiter as daemon
start_limiter() {
    if [[ -f "$PID_FILE" ]] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
        echo -e "${yellow}Limiter is already running (PID: $(cat "$PID_FILE"))${rest}"
        return
    fi
    
    echo -e "${green}Starting MonsterVps connection limiter...${rest}"
    nohup "$0" monitor > /dev/null 2>&1 &
    echo -e "${green}Limiter started successfully${rest}"
}

# Stop limiter
stop_limiter() {
    if [[ -f "$PID_FILE" ]]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            rm -f "$PID_FILE"
            echo -e "${green}Limiter stopped successfully${rest}"
        else
            echo -e "${yellow}Limiter is not running${rest}"
            rm -f "$PID_FILE"
        fi
    else
        echo -e "${yellow}No PID file found${rest}"
    fi
}

# Show limiter status
show_status() {
    echo -e "${cyan}=== MonsterVps Connection Limiter Status ===${rest}"
    echo ""
    
    if [[ -f "$PID_FILE" ]] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
        echo -e "${green}Status: Running (PID: $(cat "$PID_FILE"))${rest}"
    else
        echo -e "${red}Status: Stopped${rest}"
    fi
    
    echo ""
    echo -e "${cyan}Configuration:${rest}"
    echo -e "  SSH Default Limit: $SSH_DEFAULT_LIMIT"
    echo -e "  V2Ray Default Limit: $V2RAY_DEFAULT_LIMIT"
    echo -e "  WireGuard Default Limit: $WIREGUARD_DEFAULT_LIMIT"
    echo -e "  Check Interval: $CHECK_INTERVAL seconds"
    echo -e "  Action on Exceed: $ACTION_ON_EXCEED"
    echo -e "  Email Notifications: $EMAIL_NOTIFICATIONS"
    echo -e "  Whitelist Users: $WHITELIST_USERS"
    
    echo ""
    echo -e "${cyan}Recent Log Entries:${rest}"
    if [[ -f "$LOG_FILE" ]]; then
        tail -10 "$LOG_FILE"
    else
        echo "No log file found"
    fi
}

# Configuration menu
configure_limiter() {
    while true; do
        echo -e "${cyan}=== MonsterVps Connection Limiter Configuration ===${rest}"
        echo ""
        echo "1) SSH Default Limit: $SSH_DEFAULT_LIMIT"
        echo "2) V2Ray Default Limit: $V2RAY_DEFAULT_LIMIT"
        echo "3) WireGuard Default Limit: $WIREGUARD_DEFAULT_LIMIT"
        echo "4) Check Interval: $CHECK_INTERVAL seconds"
        echo "5) Action on Exceed: $ACTION_ON_EXCEED"
        echo "6) Email Notifications: $EMAIL_NOTIFICATIONS"
        echo "7) Email Address: $EMAIL_TO"
        echo "8) Whitelist Users: $WHITELIST_USERS"
        echo "9) Save Configuration"
        echo "0) Back to Main Menu"
        echo ""
        read -p "Select option: " option
        
        case $option in
            1)
                read -p "Enter SSH default limit: " SSH_DEFAULT_LIMIT
                ;;
            2)
                read -p "Enter V2Ray default limit: " V2RAY_DEFAULT_LIMIT
                ;;
            3)
                read -p "Enter WireGuard default limit: " WIREGUARD_DEFAULT_LIMIT
                ;;
            4)
                read -p "Enter check interval (seconds): " CHECK_INTERVAL
                ;;
            5)
                echo "Actions: kill, disable, warn"
                read -p "Enter action on exceed: " ACTION_ON_EXCEED
                ;;
            6)
                echo "Enable email notifications? (true/false)"
                read -p "Enter choice: " EMAIL_NOTIFICATIONS
                ;;
            7)
                read -p "Enter email address: " EMAIL_TO
                ;;
            8)
                read -p "Enter whitelist users (comma-separated): " WHITELIST_USERS
                ;;
            9)
                save_config
                echo -e "${green}Configuration saved${rest}"
                ;;
            0)
                break
                ;;
            *)
                echo -e "${red}Invalid option${rest}"
                ;;
        esac
    done
}

# Main menu
main_menu() {
    while true; do
        clear
        echo -e "${cyan}┌─────────────────────────────────────────────────────────────┐${rest}"
        echo -e "${cyan}│                   MonsterVps Connection Limiter            │${rest}"
        echo -e "${cyan}│                      by mastermind                         │${rest}"
        echo -e "${cyan}└─────────────────────────────────────────────────────────────┘${rest}"
        echo ""
        echo -e "${green}1)${rest} Start Limiter"
        echo -e "${green}2)${rest} Stop Limiter"
        echo -e "${green}3)${rest} Show Status"
        echo -e "${green}4)${rest} Configure Limiter"
        echo -e "${green}5)${rest} View Logs"
        echo -e "${green}6)${rest} Test Limits"
        echo -e "${green}0)${rest} Exit"
        echo ""
        read -p "Select option: " option
        
        case $option in
            1)
                start_limiter
                read -p "Press Enter to continue..."
                ;;
            2)
                stop_limiter
                read -p "Press Enter to continue..."
                ;;
            3)
                show_status
                read -p "Press Enter to continue..."
                ;;
            4)
                configure_limiter
                ;;
            5)
                if [[ -f "$LOG_FILE" ]]; then
                    less "$LOG_FILE"
                else
                    echo -e "${yellow}No log file found${rest}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            6)
                echo -e "${yellow}Testing connection limits...${rest}"
                check_ssh_limits
                check_v2ray_limits
                check_wireguard_limits
                echo -e "${green}Test completed. Check logs for results.${rest}"
                read -p "Press Enter to continue..."
                ;;
            0)
                exit 0
                ;;
            *)
                echo -e "${red}Invalid option${rest}"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Initialize
load_config
mkdir -p /etc/MonsterVps
mkdir -p /var/log

# Handle command line arguments
case "$1" in
    "start")
        start_limiter
        ;;
    "stop")
        stop_limiter
        ;;
    "status")
        show_status
        ;;
    "monitor")
        monitor_connections
        ;;
    "configure")
        configure_limiter
        ;;
    *)
        main_menu
        ;;
esac