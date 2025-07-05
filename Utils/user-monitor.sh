#!/bin/bash

# MonsterVps User Monitor System - mastermind
# Comprehensive user monitoring and management system

# Colors
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[1;33m'
blue='\033[0;34m'
cyan='\033[0;36m'
rest='\033[0m'

# Configuration
MONITOR_DIR="/etc/MonsterVps/monitor"
LOG_FILE="/var/log/monstervps_monitor.log"
PID_FILE="/var/run/monstervps_monitor.pid"
DB_FILE="/etc/MonsterVps/db/users.db"

# Default settings
MONITOR_INTERVAL=60
CLEANUP_EXPIRED=true
AUTO_BACKUP=true
BACKUP_INTERVAL=3600
MAX_LOG_SIZE=10485760  # 10MB
ALERT_THRESHOLD=80     # Alert when connections reach 80% of limit

# Database functions
init_database() {
    mkdir -p "$(dirname "$DB_FILE")"
    
    sqlite3 "$DB_FILE" << 'EOF'
CREATE TABLE IF NOT EXISTS ssh_users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    connection_limit INTEGER DEFAULT 2,
    expiry_date TEXT NOT NULL,
    created_date TEXT DEFAULT CURRENT_TIMESTAMP,
    last_login TEXT,
    status TEXT DEFAULT 'active'
);

CREATE TABLE IF NOT EXISTS v2ray_users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    uuid TEXT UNIQUE NOT NULL,
    connection_limit INTEGER DEFAULT 5,
    expiry_date TEXT NOT NULL,
    created_date TEXT DEFAULT CURRENT_TIMESTAMP,
    last_connection TEXT,
    total_traffic INTEGER DEFAULT 0,
    status TEXT DEFAULT 'active'
);

CREATE TABLE IF NOT EXISTS wireguard_users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    public_key TEXT UNIQUE NOT NULL,
    private_key TEXT NOT NULL,
    connection_limit INTEGER DEFAULT 3,
    expiry_date TEXT NOT NULL,
    created_date TEXT DEFAULT CURRENT_TIMESTAMP,
    last_handshake TEXT,
    total_traffic INTEGER DEFAULT 0,
    status TEXT DEFAULT 'active'
);

CREATE TABLE IF NOT EXISTS connection_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL,
    protocol TEXT NOT NULL,
    connection_time TEXT DEFAULT CURRENT_TIMESTAMP,
    disconnection_time TEXT,
    ip_address TEXT,
    bytes_sent INTEGER DEFAULT 0,
    bytes_received INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS user_activities (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL,
    activity_type TEXT NOT NULL,
    description TEXT,
    timestamp TEXT DEFAULT CURRENT_TIMESTAMP
);
EOF
}

# Logging function
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    # Rotate log if too large
    if [[ -f "$LOG_FILE" ]] && [[ $(stat -f%z "$LOG_FILE" 2>/dev/null || stat -c%s "$LOG_FILE" 2>/dev/null) -gt $MAX_LOG_SIZE ]]; then
        mv "$LOG_FILE" "${LOG_FILE}.old"
        touch "$LOG_FILE"
    fi
}

# Get user information
get_user_info() {
    local username="$1"
    local protocol="$2"
    
    case $protocol in
        "ssh")
            sqlite3 "$DB_FILE" "SELECT username, connection_limit, expiry_date, status FROM ssh_users WHERE username='$username';"
            ;;
        "v2ray")
            sqlite3 "$DB_FILE" "SELECT username, connection_limit, expiry_date, status FROM v2ray_users WHERE username='$username';"
            ;;
        "wireguard")
            sqlite3 "$DB_FILE" "SELECT username, connection_limit, expiry_date, status FROM wireguard_users WHERE username='$username';"
            ;;
    esac
}

# Monitor SSH connections
monitor_ssh_connections() {
    log_message "DEBUG" "Monitoring SSH connections"
    
    # Get current SSH sessions
    who -u | while read line; do
        local username=$(echo "$line" | awk '{print $1}')
        local tty=$(echo "$line" | awk '{print $2}')
        local login_time=$(echo "$line" | awk '{print $3" "$4}')
        local pid=$(echo "$line" | awk '{print $6}')
        local ip=$(echo "$line" | awk '{print $5}' | tr -d '()')
        
        # Skip if not a valid user session
        [[ -z "$username" ]] && continue
        
        # Check if user exists in database
        local user_info=$(get_user_info "$username" "ssh")
        
        if [[ -n "$user_info" ]]; then
            # Update last login
            sqlite3 "$DB_FILE" "UPDATE ssh_users SET last_login='$(date '+%Y-%m-%d %H:%M:%S')' WHERE username='$username';"
            
            # Log connection activity
            sqlite3 "$DB_FILE" "INSERT OR IGNORE INTO connection_logs (username, protocol, ip_address) VALUES ('$username', 'ssh', '$ip');"
            
            # Check connection limit
            local current_connections=$(ps aux | grep -c "sshd.*$username")
            local connection_limit=$(echo "$user_info" | cut -d'|' -f2)
            
            if [[ $current_connections -ge $((connection_limit * ALERT_THRESHOLD / 100)) ]]; then
                log_message "WARN" "User $username approaching SSH connection limit: $current_connections/$connection_limit"
            fi
        fi
    done
}

# Monitor V2Ray connections
monitor_v2ray_connections() {
    log_message "DEBUG" "Monitoring V2Ray connections"
    
    if [[ ! -f /var/log/v2ray/access.log ]]; then
        return
    fi
    
    # Parse V2Ray access log for recent connections
    local current_time=$(date +%s)
    local cutoff_time=$((current_time - 300)) # Last 5 minutes
    
    # Extract unique users from recent log entries
    awk -v cutoff="$cutoff_time" '
    {
        # Parse V2Ray log format to extract user email and timestamp
        if (match($0, /email: ([^,\s]+)/, user) && match($0, /^([0-9]{4}\/[0-9]{2}\/[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2})/, timestamp)) {
            # Convert timestamp to epoch
            cmd = "date -d \"" timestamp[1] "\" +%s 2>/dev/null || echo 0"
            cmd | getline epoch
            close(cmd)
            
            if (epoch >= cutoff) {
                users[user[1]]++
            }
        }
    }
    END {
        for (user in users) {
            print user, users[user]
        }
    }' /var/log/v2ray/access.log | while read user_email connections; do
        # Update connection information
        sqlite3 "$DB_FILE" "UPDATE v2ray_users SET last_connection='$(date '+%Y-%m-%d %H:%M:%S')' WHERE email='$user_email';"
        
        # Log activity
        sqlite3 "$DB_FILE" "INSERT INTO user_activities (username, activity_type, description) VALUES ('$user_email', 'v2ray_connection', 'Active connections: $connections');"
    done
}

# Monitor WireGuard connections
monitor_wireguard_connections() {
    log_message "DEBUG" "Monitoring WireGuard connections"
    
    if ! command -v wg &> /dev/null; then
        return
    fi
    
    # Get WireGuard peer information
    wg show all dump | while read interface public_key preshared_key endpoint allowed_ips latest_handshake transfer_rx transfer_tx persistent_keepalive; do
        [[ "$interface" == "interface" ]] && continue
        
        # Get username for this public key
        local username=$(sqlite3 "$DB_FILE" "SELECT username FROM wireguard_users WHERE public_key='$public_key';" 2>/dev/null)
        
        if [[ -n "$username" ]]; then
            # Update handshake time
            sqlite3 "$DB_FILE" "UPDATE wireguard_users SET last_handshake='$(date '+%Y-%m-%d %H:%M:%S')' WHERE username='$username';"
            
            # Update traffic statistics
            if [[ "$transfer_rx" != "0" ]] || [[ "$transfer_tx" != "0" ]]; then
                sqlite3 "$DB_FILE" "UPDATE wireguard_users SET total_traffic=total_traffic+$transfer_rx+$transfer_tx WHERE username='$username';"
            fi
            
            # Log activity
            local current_time=$(date +%s)
            if [[ $((current_time - latest_handshake)) -lt 300 ]]; then
                sqlite3 "$DB_FILE" "INSERT INTO user_activities (username, activity_type, description) VALUES ('$username', 'wireguard_active', 'Recent handshake, RX: $transfer_rx, TX: $transfer_tx');"
            fi
        fi
    done
}

# Check and remove expired users
cleanup_expired_users() {
    log_message "INFO" "Checking for expired users"
    
    local current_date=$(date '+%Y-%m-%d')
    
    # Find expired SSH users
    sqlite3 "$DB_FILE" "SELECT username FROM ssh_users WHERE expiry_date < '$current_date' AND status='active';" | while read username; do
        log_message "INFO" "Disabling expired SSH user: $username"
        
        # Disable user
        usermod -L "$username" 2>/dev/null || true
        
        # Update database
        sqlite3 "$DB_FILE" "UPDATE ssh_users SET status='expired' WHERE username='$username';"
        
        # Kill active sessions
        pkill -u "$username" 2>/dev/null || true
        
        # Log activity
        sqlite3 "$DB_FILE" "INSERT INTO user_activities (username, activity_type, description) VALUES ('$username', 'account_expired', 'SSH account disabled due to expiration');"
    done
    
    # Find expired V2Ray users
    sqlite3 "$DB_FILE" "SELECT email FROM v2ray_users WHERE expiry_date < '$current_date' AND status='active';" | while read email; do
        log_message "INFO" "Disabling expired V2Ray user: $email"
        
        # Update database
        sqlite3 "$DB_FILE" "UPDATE v2ray_users SET status='expired' WHERE email='$email';"
        
        # Remove from V2Ray config (would need V2Ray API implementation)
        # This is a placeholder for V2Ray user removal
        
        # Log activity
        sqlite3 "$DB_FILE" "INSERT INTO user_activities (username, activity_type, description) VALUES ('$email', 'account_expired', 'V2Ray account disabled due to expiration');"
    done
    
    # Find expired WireGuard users
    sqlite3 "$DB_FILE" "SELECT username, public_key FROM wireguard_users WHERE expiry_date < '$current_date' AND status='active';" | while read username public_key; do
        log_message "INFO" "Disabling expired WireGuard user: $username"
        
        # Remove peer from WireGuard
        wg set wg0 peer "$public_key" remove 2>/dev/null || true
        
        # Update database
        sqlite3 "$DB_FILE" "UPDATE wireguard_users SET status='expired' WHERE username='$username';"
        
        # Log activity
        sqlite3 "$DB_FILE" "INSERT INTO user_activities (username, activity_type, description) VALUES ('$username', 'account_expired', 'WireGuard account disabled due to expiration');"
    done
}

# Generate usage report
generate_usage_report() {
    local report_file="/tmp/monstervps_usage_report.txt"
    
    cat > "$report_file" << 'EOF'
==================================================
         MonsterVps Usage Report
==================================================

Generated: $(date)

SSH Users Summary:
--------------------------------------------------
EOF
    
    sqlite3 "$DB_FILE" << 'EOF' >> "$report_file"
.headers on
.mode column
.width 15 10 12 8 15
SELECT 
    username,
    connection_limit as "Max Conn",
    expiry_date as "Expires",
    status,
    last_login as "Last Login"
FROM ssh_users 
ORDER BY username;

.print ""
.print "V2Ray Users Summary:"
.print "--------------------------------------------------"
SELECT 
    username,
    connection_limit as "Max Conn",
    expiry_date as "Expires", 
    status,
    last_connection as "Last Conn"
FROM v2ray_users 
ORDER BY username;

.print ""
.print "WireGuard Users Summary:"
.print "--------------------------------------------------"
SELECT 
    username,
    connection_limit as "Max Conn",
    expiry_date as "Expires",
    status,
    last_handshake as "Last Handshake"
FROM wireguard_users 
ORDER BY username;

.print ""
.print "Recent User Activities (Last 24 hours):"
.print "--------------------------------------------------"
SELECT 
    username,
    activity_type as "Activity",
    description as "Description",
    timestamp
FROM user_activities 
WHERE datetime(timestamp) > datetime('now', '-1 day')
ORDER BY timestamp DESC
LIMIT 20;
EOF
    
    echo "$report_file"
}

# Backup database
backup_database() {
    local backup_dir="/etc/MonsterVps/backups"
    local backup_file="$backup_dir/users_$(date +%Y%m%d_%H%M%S).db"
    
    mkdir -p "$backup_dir"
    
    if cp "$DB_FILE" "$backup_file"; then
        log_message "INFO" "Database backup created: $backup_file"
        
        # Keep only last 7 days of backups
        find "$backup_dir" -name "users_*.db" -type f -mtime +7 -delete
    else
        log_message "ERROR" "Failed to create database backup"
    fi
}

# Main monitoring loop
monitor_loop() {
    log_message "INFO" "Starting MonsterVps user monitor (PID: $$)"
    echo $$ > "$PID_FILE"
    
    local last_backup=$(date +%s)
    
    while true; do
        monitor_ssh_connections
        monitor_v2ray_connections
        monitor_wireguard_connections
        
        if [[ "$CLEANUP_EXPIRED" == "true" ]]; then
            cleanup_expired_users
        fi
        
        # Auto backup
        if [[ "$AUTO_BACKUP" == "true" ]]; then
            local current_time=$(date +%s)
            if [[ $((current_time - last_backup)) -gt $BACKUP_INTERVAL ]]; then
                backup_database
                last_backup=$current_time
            fi
        fi
        
        sleep "$MONITOR_INTERVAL"
    done
}

# Start monitor
start_monitor() {
    if [[ -f "$PID_FILE" ]] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
        echo -e "${yellow}Monitor is already running (PID: $(cat "$PID_FILE"))${rest}"
        return
    fi
    
    echo -e "${green}Starting MonsterVps user monitor...${rest}"
    nohup "$0" loop > /dev/null 2>&1 &
    echo -e "${green}Monitor started successfully${rest}"
}

# Stop monitor
stop_monitor() {
    if [[ -f "$PID_FILE" ]]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            rm -f "$PID_FILE"
            echo -e "${green}Monitor stopped successfully${rest}"
        else
            echo -e "${yellow}Monitor is not running${rest}"
            rm -f "$PID_FILE"
        fi
    else
        echo -e "${yellow}No PID file found${rest}"
    fi
}

# Show monitor status
show_status() {
    echo -e "${cyan}=== MonsterVps User Monitor Status ===${rest}"
    echo ""
    
    if [[ -f "$PID_FILE" ]] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
        echo -e "${green}Status: Running (PID: $(cat "$PID_FILE"))${rest}"
    else
        echo -e "${red}Status: Stopped${rest}"
    fi
    
    echo ""
    echo -e "${cyan}Database Statistics:${rest}"
    
    local ssh_users=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM ssh_users WHERE status='active';" 2>/dev/null || echo "0")
    local v2ray_users=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM v2ray_users WHERE status='active';" 2>/dev/null || echo "0")
    local wg_users=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM wireguard_users WHERE status='active';" 2>/dev/null || echo "0")
    
    echo -e "  Active SSH Users: $ssh_users"
    echo -e "  Active V2Ray Users: $v2ray_users"
    echo -e "  Active WireGuard Users: $wg_users"
    
    echo ""
    echo -e "${cyan}Recent Activities:${rest}"
    sqlite3 "$DB_FILE" "SELECT username, activity_type, timestamp FROM user_activities ORDER BY timestamp DESC LIMIT 5;" 2>/dev/null | while IFS='|' read username activity timestamp; do
        echo -e "  $timestamp - $username: $activity"
    done
}

# Main menu
main_menu() {
    while true; do
        clear
        echo -e "${cyan}┌─────────────────────────────────────────────────────────────┐${rest}"
        echo -e "${cyan}│                    MonsterVps User Monitor                  │${rest}"
        echo -e "${cyan}│                       by mastermind                        │${rest}"
        echo -e "${cyan}└─────────────────────────────────────────────────────────────┘${rest}"
        echo ""
        echo -e "${green}1)${rest} Start Monitor"
        echo -e "${green}2)${rest} Stop Monitor"
        echo -e "${green}3)${rest} Show Status"
        echo -e "${green}4)${rest} Generate Usage Report"
        echo -e "${green}5)${rest} Backup Database"
        echo -e "${green}6)${rest} View Logs"
        echo -e "${green}7)${rest} Clean Expired Users"
        echo -e "${green}0)${rest} Exit"
        echo ""
        read -p "Select option: " option
        
        case $option in
            1)
                start_monitor
                read -p "Press Enter to continue..."
                ;;
            2)
                stop_monitor
                read -p "Press Enter to continue..."
                ;;
            3)
                show_status
                read -p "Press Enter to continue..."
                ;;
            4)
                echo -e "${yellow}Generating usage report...${rest}"
                report_file=$(generate_usage_report)
                echo -e "${green}Report generated: $report_file${rest}"
                read -p "Press Enter to view report..."
                less "$report_file"
                ;;
            5)
                backup_database
                read -p "Press Enter to continue..."
                ;;
            6)
                if [[ -f "$LOG_FILE" ]]; then
                    less "$LOG_FILE"
                else
                    echo -e "${yellow}No log file found${rest}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            7)
                echo -e "${yellow}Cleaning expired users...${rest}"
                cleanup_expired_users
                echo -e "${green}Cleanup completed${rest}"
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
init_database
mkdir -p "$MONITOR_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

# Handle command line arguments
case "$1" in
    "start")
        start_monitor
        ;;
    "stop")
        stop_monitor
        ;;
    "status")
        show_status
        ;;
    "loop")
        monitor_loop
        ;;
    "backup")
        backup_database
        ;;
    "report")
        report_file=$(generate_usage_report)
        echo "Report generated: $report_file"
        ;;
    "cleanup")
        cleanup_expired_users
        ;;
    *)
        main_menu
        ;;
esac