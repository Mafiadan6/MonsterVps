#!/bin/bash

# MonsterVps Database Manager - mastermind
# Comprehensive database management system for all protocols

# Colors
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[1;33m'
blue='\033[0;34m'
cyan='\033[0;36m'
rest='\033[0m'

# Database configuration
DB_DIR="/etc/MonsterVps/db"
MAIN_DB="$DB_DIR/users.db"
BACKUP_DIR="/etc/MonsterVps/backups"
LOG_FILE="/var/log/monstervps_database.log"

# Ensure directories exist
mkdir -p "$DB_DIR" "$BACKUP_DIR"

# Logging function
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    if [[ -t 1 ]]; then
        case $level in
            "ERROR") echo -e "${red}[$timestamp] [$level] $message${rest}" ;;
            "WARN") echo -e "${yellow}[$timestamp] [$level] $message${rest}" ;;
            "INFO") echo -e "${green}[$timestamp] [$level] $message${rest}" ;;
            "DEBUG") echo -e "${blue}[$timestamp] [$level] $message${rest}" ;;
        esac
    fi
}

# Initialize database with all tables
init_database() {
    log_message "INFO" "Initializing MonsterVps database"
    
    sqlite3 "$MAIN_DB" << 'EOF'
-- SSH Users Table
CREATE TABLE IF NOT EXISTS ssh_users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    connection_limit INTEGER DEFAULT 2,
    expiry_date DATE NOT NULL,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'disabled', 'expired')),
    hwid TEXT,
    token TEXT,
    notes TEXT
);

-- V2Ray Users Table
CREATE TABLE IF NOT EXISTS v2ray_users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    uuid TEXT UNIQUE NOT NULL,
    connection_limit INTEGER DEFAULT 5,
    expiry_date DATE NOT NULL,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_connection TIMESTAMP,
    total_traffic INTEGER DEFAULT 0,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'disabled', 'expired')),
    port INTEGER,
    protocol TEXT DEFAULT 'vmess',
    notes TEXT
);

-- WireGuard Users Table
CREATE TABLE IF NOT EXISTS wireguard_users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    public_key TEXT UNIQUE NOT NULL,
    private_key TEXT NOT NULL,
    connection_limit INTEGER DEFAULT 3,
    expiry_date DATE NOT NULL,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_handshake TIMESTAMP,
    total_traffic INTEGER DEFAULT 0,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'disabled', 'expired')),
    allowed_ips TEXT DEFAULT '0.0.0.0/0',
    server_public_key TEXT,
    endpoint TEXT,
    notes TEXT
);

-- OpenVPN Users Table
CREATE TABLE IF NOT EXISTS openvpn_users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    connection_limit INTEGER DEFAULT 4,
    expiry_date DATE NOT NULL,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_connection TIMESTAMP,
    total_traffic INTEGER DEFAULT 0,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'disabled', 'expired')),
    client_cert TEXT,
    client_key TEXT,
    notes TEXT
);

-- Stunnel Users Table
CREATE TABLE IF NOT EXISTS stunnel_users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    connection_limit INTEGER DEFAULT 3,
    expiry_date DATE NOT NULL,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_connection TIMESTAMP,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'disabled', 'expired')),
    port INTEGER,
    notes TEXT
);

-- Connection Logs Table
CREATE TABLE IF NOT EXISTS connection_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL,
    protocol TEXT NOT NULL,
    connection_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    disconnection_time TIMESTAMP,
    ip_address TEXT,
    port INTEGER,
    bytes_sent INTEGER DEFAULT 0,
    bytes_received INTEGER DEFAULT 0,
    session_duration INTEGER DEFAULT 0
);

-- User Activities Table
CREATE TABLE IF NOT EXISTS user_activities (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL,
    activity_type TEXT NOT NULL,
    description TEXT,
    ip_address TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- System Settings Table
CREATE TABLE IF NOT EXISTS system_settings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    setting_name TEXT UNIQUE NOT NULL,
    setting_value TEXT,
    description TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Protocol Statistics Table
CREATE TABLE IF NOT EXISTS protocol_stats (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    protocol TEXT NOT NULL,
    active_users INTEGER DEFAULT 0,
    total_traffic INTEGER DEFAULT 0,
    peak_connections INTEGER DEFAULT 0,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_ssh_users_username ON ssh_users(username);
CREATE INDEX IF NOT EXISTS idx_ssh_users_status ON ssh_users(status);
CREATE INDEX IF NOT EXISTS idx_ssh_users_expiry ON ssh_users(expiry_date);

CREATE INDEX IF NOT EXISTS idx_v2ray_users_email ON v2ray_users(email);
CREATE INDEX IF NOT EXISTS idx_v2ray_users_uuid ON v2ray_users(uuid);
CREATE INDEX IF NOT EXISTS idx_v2ray_users_status ON v2ray_users(status);

CREATE INDEX IF NOT EXISTS idx_wireguard_users_username ON wireguard_users(username);
CREATE INDEX IF NOT EXISTS idx_wireguard_users_public_key ON wireguard_users(public_key);
CREATE INDEX IF NOT EXISTS idx_wireguard_users_status ON wireguard_users(status);

CREATE INDEX IF NOT EXISTS idx_connection_logs_username ON connection_logs(username);
CREATE INDEX IF NOT EXISTS idx_connection_logs_protocol ON connection_logs(protocol);
CREATE INDEX IF NOT EXISTS idx_connection_logs_time ON connection_logs(connection_time);

CREATE INDEX IF NOT EXISTS idx_user_activities_username ON user_activities(username);
CREATE INDEX IF NOT EXISTS idx_user_activities_timestamp ON user_activities(timestamp);

-- Insert default system settings
INSERT OR REPLACE INTO system_settings (setting_name, setting_value, description) VALUES 
('default_ssh_limit', '2', 'Default SSH connection limit'),
('default_v2ray_limit', '5', 'Default V2Ray connection limit'),
('default_wireguard_limit', '3', 'Default WireGuard connection limit'),
('default_openvpn_limit', '4', 'Default OpenVPN connection limit'),
('default_stunnel_limit', '3', 'Default Stunnel connection limit'),
('auto_cleanup_expired', 'true', 'Automatically cleanup expired users'),
('backup_interval', '3600', 'Database backup interval in seconds'),
('log_retention_days', '30', 'Number of days to keep logs'),
('max_concurrent_users', '1000', 'Maximum concurrent users across all protocols'),
('system_version', '1.0.0', 'MonsterVps system version');
EOF
    
    if [[ $? -eq 0 ]]; then
        log_message "INFO" "Database initialized successfully"
        return 0
    else
        log_message "ERROR" "Failed to initialize database"
        return 1
    fi
}

# Add SSH user
add_ssh_user() {
    local username="$1"
    local password="$2"
    local days="$3"
    local limit="${4:-2}"
    
    local expiry_date=$(date -d "+$days days" '+%Y-%m-%d')
    
    # Create system user
    useradd -m -s /bin/bash "$username" 2>/dev/null
    echo "$username:$password" | chpasswd
    
    # Add to database
    sqlite3 "$MAIN_DB" "INSERT INTO ssh_users (username, password, connection_limit, expiry_date) VALUES ('$username', '$password', $limit, '$expiry_date');"
    
    if [[ $? -eq 0 ]]; then
        log_message "INFO" "SSH user $username created successfully"
        sqlite3 "$MAIN_DB" "INSERT INTO user_activities (username, activity_type, description) VALUES ('$username', 'user_created', 'SSH user created with $days days validity');"
        return 0
    else
        log_message "ERROR" "Failed to create SSH user $username"
        return 1
    fi
}

# Add V2Ray user
add_v2ray_user() {
    local username="$1"
    local email="$2"
    local days="$3"
    local limit="${4:-5}"
    
    local uuid=$(uuidgen)
    local expiry_date=$(date -d "+$days days" '+%Y-%m-%d')
    
    # Add to database
    sqlite3 "$MAIN_DB" "INSERT INTO v2ray_users (username, email, uuid, connection_limit, expiry_date) VALUES ('$username', '$email', '$uuid', $limit, '$expiry_date');"
    
    if [[ $? -eq 0 ]]; then
        log_message "INFO" "V2Ray user $username created successfully"
        sqlite3 "$MAIN_DB" "INSERT INTO user_activities (username, activity_type, description) VALUES ('$username', 'user_created', 'V2Ray user created with $days days validity');"
        echo "UUID: $uuid"
        return 0
    else
        log_message "ERROR" "Failed to create V2Ray user $username"
        return 1
    fi
}

# Add WireGuard user
add_wireguard_user() {
    local username="$1"
    local days="$2"
    local limit="${3:-3}"
    
    local expiry_date=$(date -d "+$days days" '+%Y-%m-%d')
    
    # Generate key pair
    local private_key=$(wg genkey)
    local public_key=$(echo "$private_key" | wg pubkey)
    
    # Add to database
    sqlite3 "$MAIN_DB" "INSERT INTO wireguard_users (username, public_key, private_key, connection_limit, expiry_date) VALUES ('$username', '$public_key', '$private_key', $limit, '$expiry_date');"
    
    if [[ $? -eq 0 ]]; then
        log_message "INFO" "WireGuard user $username created successfully"
        sqlite3 "$MAIN_DB" "INSERT INTO user_activities (username, activity_type, description) VALUES ('$username', 'user_created', 'WireGuard user created with $days days validity');"
        echo "Public Key: $public_key"
        echo "Private Key: $private_key"
        return 0
    else
        log_message "ERROR" "Failed to create WireGuard user $username"
        return 1
    fi
}

# List users by protocol
list_users() {
    local protocol="$1"
    
    case $protocol in
        "ssh")
            echo -e "${cyan}SSH Users:${rest}"
            sqlite3 "$MAIN_DB" << 'EOF'
.headers on
.mode column
.width 15 12 12 8 10 15
SELECT username, connection_limit, expiry_date, status, last_login, created_date FROM ssh_users ORDER BY username;
EOF
            ;;
        "v2ray")
            echo -e "${cyan}V2Ray Users:${rest}"
            sqlite3 "$MAIN_DB" << 'EOF'
.headers on
.mode column
.width 15 20 12 8 15 15
SELECT username, email, connection_limit, expiry_date, status, last_connection FROM v2ray_users ORDER BY username;
EOF
            ;;
        "wireguard")
            echo -e "${cyan}WireGuard Users:${rest}"
            sqlite3 "$MAIN_DB" << 'EOF'
.headers on
.mode column
.width 15 12 8 15 15
SELECT username, connection_limit, expiry_date, status, last_handshake FROM wireguard_users ORDER BY username;
EOF
            ;;
        "all")
            list_users "ssh"
            echo ""
            list_users "v2ray"
            echo ""
            list_users "wireguard"
            ;;
        *)
            echo -e "${red}Invalid protocol. Use: ssh, v2ray, wireguard, or all${rest}"
            return 1
            ;;
    esac
}

# Delete user
delete_user() {
    local username="$1"
    local protocol="$2"
    
    case $protocol in
        "ssh")
            # Remove system user
            userdel -r "$username" 2>/dev/null
            
            # Remove from database
            sqlite3 "$MAIN_DB" "DELETE FROM ssh_users WHERE username='$username';"
            ;;
        "v2ray")
            sqlite3 "$MAIN_DB" "DELETE FROM v2ray_users WHERE username='$username';"
            ;;
        "wireguard")
            # Remove from WireGuard interface
            local public_key=$(sqlite3 "$MAIN_DB" "SELECT public_key FROM wireguard_users WHERE username='$username';")
            if [[ -n "$public_key" ]]; then
                wg set wg0 peer "$public_key" remove 2>/dev/null
            fi
            
            sqlite3 "$MAIN_DB" "DELETE FROM wireguard_users WHERE username='$username';"
            ;;
        *)
            echo -e "${red}Invalid protocol${rest}"
            return 1
            ;;
    esac
    
    # Log activity
    sqlite3 "$MAIN_DB" "INSERT INTO user_activities (username, activity_type, description) VALUES ('$username', 'user_deleted', 'User deleted from $protocol protocol');"
    
    log_message "INFO" "User $username deleted from $protocol protocol"
    echo -e "${green}User $username deleted successfully${rest}"
}

# Extend user expiry
extend_user() {
    local username="$1"
    local protocol="$2"
    local additional_days="$3"
    
    local new_expiry_date=$(date -d "+$additional_days days" '+%Y-%m-%d')
    
    case $protocol in
        "ssh")
            sqlite3 "$MAIN_DB" "UPDATE ssh_users SET expiry_date='$new_expiry_date' WHERE username='$username';"
            ;;
        "v2ray")
            sqlite3 "$MAIN_DB" "UPDATE v2ray_users SET expiry_date='$new_expiry_date' WHERE username='$username';"
            ;;
        "wireguard")
            sqlite3 "$MAIN_DB" "UPDATE wireguard_users SET expiry_date='$new_expiry_date' WHERE username='$username';"
            ;;
        *)
            echo -e "${red}Invalid protocol${rest}"
            return 1
            ;;
    esac
    
    sqlite3 "$MAIN_DB" "INSERT INTO user_activities (username, activity_type, description) VALUES ('$username', 'user_extended', 'User extended by $additional_days days');"
    
    log_message "INFO" "User $username extended by $additional_days days"
    echo -e "${green}User $username extended successfully${rest}"
}

# Show user details
show_user_details() {
    local username="$1"
    
    echo -e "${cyan}User Details for: $username${rest}"
    echo ""
    
    # SSH user details
    local ssh_details=$(sqlite3 "$MAIN_DB" "SELECT username, connection_limit, expiry_date, status, last_login, created_date FROM ssh_users WHERE username='$username';")
    if [[ -n "$ssh_details" ]]; then
        echo -e "${yellow}SSH Details:${rest}"
        echo "$ssh_details" | tr '|' '\n' | nl -v0 -s': ' | sed 's/0: /Username: /; s/1: /Connection Limit: /; s/2: /Expiry Date: /; s/3: /Status: /; s/4: /Last Login: /; s/5: /Created Date: /'
        echo ""
    fi
    
    # V2Ray user details
    local v2ray_details=$(sqlite3 "$MAIN_DB" "SELECT username, email, uuid, connection_limit, expiry_date, status, last_connection FROM v2ray_users WHERE username='$username';")
    if [[ -n "$v2ray_details" ]]; then
        echo -e "${yellow}V2Ray Details:${rest}"
        echo "$v2ray_details" | tr '|' '\n' | nl -v0 -s': ' | sed 's/0: /Username: /; s/1: /Email: /; s/2: /UUID: /; s/3: /Connection Limit: /; s/4: /Expiry Date: /; s/5: /Status: /; s/6: /Last Connection: /'
        echo ""
    fi
    
    # WireGuard user details
    local wg_details=$(sqlite3 "$MAIN_DB" "SELECT username, public_key, connection_limit, expiry_date, status, last_handshake FROM wireguard_users WHERE username='$username';")
    if [[ -n "$wg_details" ]]; then
        echo -e "${yellow}WireGuard Details:${rest}"
        echo "$wg_details" | tr '|' '\n' | nl -v0 -s': ' | sed 's/0: /Username: /; s/1: /Public Key: /; s/2: /Connection Limit: /; s/3: /Expiry Date: /; s/4: /Status: /; s/5: /Last Handshake: /'
        echo ""
    fi
    
    # Recent activities
    echo -e "${yellow}Recent Activities:${rest}"
    sqlite3 "$MAIN_DB" "SELECT activity_type, description, timestamp FROM user_activities WHERE username='$username' ORDER BY timestamp DESC LIMIT 10;" | while IFS='|' read activity description timestamp; do
        echo "  $timestamp - $activity: $description"
    done
}

# Database backup
backup_database() {
    local backup_file="$BACKUP_DIR/monstervps_$(date +%Y%m%d_%H%M%S).db"
    
    if cp "$MAIN_DB" "$backup_file"; then
        log_message "INFO" "Database backup created: $backup_file"
        
        # Keep only last 10 backups
        ls -t "$BACKUP_DIR"/monstervps_*.db | tail -n +11 | xargs rm -f 2>/dev/null
        
        echo -e "${green}Backup created: $backup_file${rest}"
        return 0
    else
        log_message "ERROR" "Failed to create backup"
        echo -e "${red}Backup failed${rest}"
        return 1
    fi
}

# Restore database
restore_database() {
    local backup_file="$1"
    
    if [[ ! -f "$backup_file" ]]; then
        echo -e "${red}Backup file not found: $backup_file${rest}"
        return 1
    fi
    
    echo -e "${yellow}This will overwrite the current database. Are you sure? (y/N)${rest}"
    read -r confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        if cp "$backup_file" "$MAIN_DB"; then
            log_message "INFO" "Database restored from: $backup_file"
            echo -e "${green}Database restored successfully${rest}"
            return 0
        else
            log_message "ERROR" "Failed to restore database"
            echo -e "${red}Restore failed${rest}"
            return 1
        fi
    else
        echo -e "${yellow}Restore cancelled${rest}"
        return 1
    fi
}

# Show database statistics
show_statistics() {
    echo -e "${cyan}=== MonsterVps Database Statistics ===${rest}"
    echo ""
    
    local ssh_count=$(sqlite3 "$MAIN_DB" "SELECT COUNT(*) FROM ssh_users WHERE status='active';")
    local v2ray_count=$(sqlite3 "$MAIN_DB" "SELECT COUNT(*) FROM v2ray_users WHERE status='active';")
    local wg_count=$(sqlite3 "$MAIN_DB" "SELECT COUNT(*) FROM wireguard_users WHERE status='active';")
    local total_users=$((ssh_count + v2ray_count + wg_count))
    
    echo -e "${green}Active Users:${rest}"
    echo -e "  SSH: $ssh_count"
    echo -e "  V2Ray: $v2ray_count"
    echo -e "  WireGuard: $wg_count"
    echo -e "  Total: $total_users"
    echo ""
    
    local expired_count=$(sqlite3 "$MAIN_DB" "SELECT COUNT(*) FROM ssh_users WHERE status='expired' UNION ALL SELECT COUNT(*) FROM v2ray_users WHERE status='expired' UNION ALL SELECT COUNT(*) FROM wireguard_users WHERE status='expired';" | awk '{sum+=$1} END {print sum}')
    echo -e "${yellow}Expired Users: $expired_count${rest}"
    echo ""
    
    echo -e "${cyan}Recent Activities (Last 24 hours):${rest}"
    sqlite3 "$MAIN_DB" "SELECT COUNT(*) FROM user_activities WHERE datetime(timestamp) > datetime('now', '-1 day');" | while read count; do
        echo -e "  Activities: $count"
    done
    echo ""
    
    echo -e "${cyan}Database Size:${rest}"
    local db_size=$(du -h "$MAIN_DB" | cut -f1)
    echo -e "  Size: $db_size"
    
    local backup_count=$(ls -1 "$BACKUP_DIR"/monstervps_*.db 2>/dev/null | wc -l)
    echo -e "  Backups: $backup_count"
}

# Clean expired users
clean_expired_users() {
    local current_date=$(date '+%Y-%m-%d')
    
    echo -e "${yellow}Cleaning expired users...${rest}"
    
    # SSH users
    local ssh_expired=$(sqlite3 "$MAIN_DB" "SELECT COUNT(*) FROM ssh_users WHERE expiry_date < '$current_date' AND status='active';")
    if [[ $ssh_expired -gt 0 ]]; then
        sqlite3 "$MAIN_DB" "SELECT username FROM ssh_users WHERE expiry_date < '$current_date' AND status='active';" | while read username; do
            userdel -r "$username" 2>/dev/null
        done
        sqlite3 "$MAIN_DB" "UPDATE ssh_users SET status='expired' WHERE expiry_date < '$current_date' AND status='active';"
        echo -e "${green}Cleaned $ssh_expired expired SSH users${rest}"
    fi
    
    # V2Ray users
    local v2ray_expired=$(sqlite3 "$MAIN_DB" "SELECT COUNT(*) FROM v2ray_users WHERE expiry_date < '$current_date' AND status='active';")
    if [[ $v2ray_expired -gt 0 ]]; then
        sqlite3 "$MAIN_DB" "UPDATE v2ray_users SET status='expired' WHERE expiry_date < '$current_date' AND status='active';"
        echo -e "${green}Cleaned $v2ray_expired expired V2Ray users${rest}"
    fi
    
    # WireGuard users
    local wg_expired=$(sqlite3 "$MAIN_DB" "SELECT COUNT(*) FROM wireguard_users WHERE expiry_date < '$current_date' AND status='active';")
    if [[ $wg_expired -gt 0 ]]; then
        sqlite3 "$MAIN_DB" "SELECT username, public_key FROM wireguard_users WHERE expiry_date < '$current_date' AND status='active';" | while IFS='|' read username public_key; do
            wg set wg0 peer "$public_key" remove 2>/dev/null
        done
        sqlite3 "$MAIN_DB" "UPDATE wireguard_users SET status='expired' WHERE expiry_date < '$current_date' AND status='active';"
        echo -e "${green}Cleaned $wg_expired expired WireGuard users${rest}"
    fi
    
    log_message "INFO" "Cleaned expired users: SSH=$ssh_expired, V2Ray=$v2ray_expired, WireGuard=$wg_expired"
}

# Main menu
main_menu() {
    while true; do
        clear
        echo -e "${cyan}┌─────────────────────────────────────────────────────────────┐${rest}"
        echo -e "${cyan}│                MonsterVps Database Manager                  │${rest}"
        echo -e "${cyan}│                      by mastermind                         │${rest}"
        echo -e "${cyan}└─────────────────────────────────────────────────────────────┘${rest}"
        echo ""
        echo -e "${green}User Management:${rest}"
        echo -e "${green}1)${rest} List Users"
        echo -e "${green}2)${rest} Add User"
        echo -e "${green}3)${rest} Delete User"
        echo -e "${green}4)${rest} Extend User"
        echo -e "${green}5)${rest} Show User Details"
        echo ""
        echo -e "${green}Database Operations:${rest}"
        echo -e "${green}6)${rest} Backup Database"
        echo -e "${green}7)${rest} Restore Database"
        echo -e "${green}8)${rest} Show Statistics"
        echo -e "${green}9)${rest} Clean Expired Users"
        echo ""
        echo -e "${green}0)${rest} Exit"
        echo ""
        read -p "Select option: " option
        
        case $option in
            1)
                echo "Select protocol (ssh/v2ray/wireguard/all):"
                read -r protocol
                list_users "$protocol"
                read -p "Press Enter to continue..."
                ;;
            2)
                echo "Select protocol (ssh/v2ray/wireguard):"
                read -r protocol
                echo "Enter username:"
                read -r username
                echo "Enter validity days:"
                read -r days
                
                case $protocol in
                    "ssh")
                        echo "Enter password:"
                        read -r password
                        echo "Enter connection limit (default: 2):"
                        read -r limit
                        add_ssh_user "$username" "$password" "$days" "$limit"
                        ;;
                    "v2ray")
                        echo "Enter email:"
                        read -r email
                        echo "Enter connection limit (default: 5):"
                        read -r limit
                        add_v2ray_user "$username" "$email" "$days" "$limit"
                        ;;
                    "wireguard")
                        echo "Enter connection limit (default: 3):"
                        read -r limit
                        add_wireguard_user "$username" "$days" "$limit"
                        ;;
                esac
                read -p "Press Enter to continue..."
                ;;
            3)
                echo "Select protocol (ssh/v2ray/wireguard):"
                read -r protocol
                echo "Enter username:"
                read -r username
                delete_user "$username" "$protocol"
                read -p "Press Enter to continue..."
                ;;
            4)
                echo "Select protocol (ssh/v2ray/wireguard):"
                read -r protocol
                echo "Enter username:"
                read -r username
                echo "Enter additional days:"
                read -r days
                extend_user "$username" "$protocol" "$days"
                read -p "Press Enter to continue..."
                ;;
            5)
                echo "Enter username:"
                read -r username
                show_user_details "$username"
                read -p "Press Enter to continue..."
                ;;
            6)
                backup_database
                read -p "Press Enter to continue..."
                ;;
            7)
                echo "Available backups:"
                ls -la "$BACKUP_DIR"/monstervps_*.db 2>/dev/null || echo "No backups found"
                echo "Enter backup file path:"
                read -r backup_file
                restore_database "$backup_file"
                read -p "Press Enter to continue..."
                ;;
            8)
                show_statistics
                read -p "Press Enter to continue..."
                ;;
            9)
                clean_expired_users
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

# Initialize database and start
init_database

# Handle command line arguments
case "$1" in
    "init")
        init_database
        ;;
    "backup")
        backup_database
        ;;
    "restore")
        restore_database "$2"
        ;;
    "stats")
        show_statistics
        ;;
    "clean")
        clean_expired_users
        ;;
    "list")
        list_users "${2:-all}"
        ;;
    *)
        main_menu
        ;;
esac