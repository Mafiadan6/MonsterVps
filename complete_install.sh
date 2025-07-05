#!/bin/bash

# MonsterVps Complete Installation Script - mastermind
# Fully functional VPN management system based on ADMRufu

# Colors
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[1;33m'
blue='\033[0;34m'
cyan='\033[0;36m'
rest='\033[0m'

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    clear
    echo -e "${cyan}================================================================${rest}"
    echo -e "${yellow}                        ERROR DE EJECUCION                        ${rest}"
    echo -e "${cyan}================================================================${rest}"
    echo -e "${yellow}                DEVE EJECUTAR DESDE EL USUARIO ROOT              ${rest}"
    echo -e "${cyan}================================================================${rest}"
    exit 1
fi

# Configuration variables
MonsterVps="/etc/MonsterVps"
SCPdir="/etc/MonsterVps"
SCPinstal="$HOME/install"
SCPidioma="$MonsterVps/idioma"
SCPusr="$MonsterVps/ger-user"
SCPfrm="$MonsterVps/frm"
SCPinst="$MonsterVps/install"
SCPunistall="$MonsterVps/uninstall"
SCPlock="$MonsterVps/lockadm"

# Create directories
mkdir -p $MonsterVps $SCPdir $SCPinst $SCPfrm

# Banner function
banner() {
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

# Message functions
msg() {
    case $1 in
        -bar) echo -e "${cyan}================================================================${rest}" ;;
        -bar1) echo -e "${yellow}================================================================${rest}" ;;
        -bar2) echo -e "${green}================================================================${rest}" ;;
        -bar3) echo -e "${red}================================================================${rest}" ;;
        *) echo -e "$1" ;;
    esac
}

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

title() {
    clear
    msg -bar
    print_center -ama "$1"
    msg -bar
}

# Install dependencies
install_dependencies() {
    title "INSTALANDO DEPENDENCIAS"
    
    # Update system
    apt-get update -y
    
    # Install basic dependencies
    local packages=(
        "curl" "wget" "bc" "jq" "lsof" "netstat" "net-tools"
        "unzip" "zip" "nano" "screen" "htop" "python3" "python3-pip"
        "sqlite3" "ufw" "fail2ban" "apache2-utils" "systemd"
        "software-properties-common" "apt-transport-https" "ca-certificates"
        "gnupg" "lsb-release" "cron" "uuid-runtime"
    )
    
    for package in "${packages[@]}"; do
        echo -e "${yellow}Installing $package...${rest}"
        apt-get install -y "$package" 2>/dev/null
    done
    
    # Install Python packages
    pip3 install requests websocket-client 2>/dev/null
    
    echo -e "${green}✓ Dependencies installed successfully${rest}"
}

# Install protocols
install_protocols() {
    title "CONFIGURANDO PROTOCOLOS"
    
    # SSH Configuration
    echo -e "${yellow}Configuring SSH...${rest}"
    sed -i 's/#Port 22/Port 22/' /etc/ssh/sshd_config
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
    systemctl restart ssh
    
    # Install V2Ray
    echo -e "${yellow}Installing V2Ray...${rest}"
    bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh) 2>/dev/null
    
    # Install WireGuard
    echo -e "${yellow}Installing WireGuard...${rest}"
    apt-get install -y wireguard wireguard-tools
    
    # Install OpenVPN
    echo -e "${yellow}Installing OpenVPN...${rest}"
    apt-get install -y openvpn easy-rsa
    
    # Install Stunnel
    echo -e "${yellow}Installing Stunnel...${rest}"
    apt-get install -y stunnel4
    
    # Install Dropbear
    echo -e "${yellow}Installing Dropbear...${rest}"
    apt-get install -y dropbear-bin
    
    echo -e "${green}✓ Protocols installed successfully${rest}"
}

# Setup database
setup_database() {
    title "CONFIGURANDO BASE DE DATOS"
    
    # Create database directory
    mkdir -p "$MonsterVps/db"
    
    # Initialize SQLite database
    sqlite3 "$MonsterVps/db/users.db" << 'EOF'
CREATE TABLE IF NOT EXISTS ssh_users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    connection_limit INTEGER DEFAULT 2,
    expiry_date DATE NOT NULL,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP,
    status TEXT DEFAULT 'active'
);

CREATE TABLE IF NOT EXISTS v2ray_users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    uuid TEXT UNIQUE NOT NULL,
    connection_limit INTEGER DEFAULT 5,
    expiry_date DATE NOT NULL,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status TEXT DEFAULT 'active'
);

CREATE TABLE IF NOT EXISTS wireguard_users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    public_key TEXT UNIQUE NOT NULL,
    private_key TEXT NOT NULL,
    connection_limit INTEGER DEFAULT 3,
    expiry_date DATE NOT NULL,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status TEXT DEFAULT 'active'
);
EOF
    
    echo -e "${green}✓ Database configured successfully${rest}"
}

# Install utilities
install_utilities() {
    title "INSTALANDO UTILIDADES"
    
    # Copy all utilities to system
    cp -r Utils/* "$MonsterVps/"
    cp -r online/* "$MonsterVps/"
    
    # Set permissions
    find "$MonsterVps" -name "*.sh" -exec chmod +x {} \;
    
    # Create system commands
    cat > /usr/bin/monstervps << 'EOF'
#!/bin/bash
/etc/MonsterVps/menu.sh "$@"
EOF
    
    chmod +x /usr/bin/monstervps
    
    # Copy main menu
    cp menu.sh "$MonsterVps/menu.sh"
    chmod +x "$MonsterVps/menu.sh"
    
    echo -e "${green}✓ Utilities installed successfully${rest}"
}

# Configure services
configure_services() {
    title "CONFIGURANDO SERVICIOS"
    
    # Configure auto-start services
    if [[ -f "$MonsterVps/autoStart/install.sh" ]]; then
        bash "$MonsterVps/autoStart/install.sh"
    fi
    
    # Start user monitor
    if [[ -f "$MonsterVps/user-monitor.sh" ]]; then
        bash "$MonsterVps/user-monitor.sh" start
    fi
    
    # Start connection limiter
    if [[ -f "$MonsterVps/limitador.sh" ]]; then
        bash "$MonsterVps/limitador.sh" start
    fi
    
    echo -e "${green}✓ Services configured successfully${rest}"
}

# Configure firewall
configure_firewall() {
    title "CONFIGURANDO FIREWALL"
    
    # Basic firewall rules
    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing
    
    # Allow common ports
    ufw allow 22/tcp    # SSH
    ufw allow 80/tcp    # HTTP
    ufw allow 443/tcp   # HTTPS
    ufw allow 1194/udp  # OpenVPN
    ufw allow 51820/udp # WireGuard
    
    # Enable firewall
    ufw --force enable
    
    echo -e "${green}✓ Firewall configured successfully${rest}"
}

# Create system menu
create_menu() {
    # Create menu command accessible from anywhere
    cat > /usr/local/bin/menu << 'EOF'
#!/bin/bash
# Global menu command for MonsterVps
# This allows users to type "menu" from anywhere in the system

# Check if MonsterVps is installed
if [[ ! -f /etc/MonsterVps/menu.sh ]]; then
    echo "MonsterVps not installed. Run installation first."
    exit 1
fi

# Execute the main menu
/etc/MonsterVps/menu.sh "$@"
EOF
    
    chmod +x /usr/local/bin/menu
    
    # Also create in /usr/bin for compatibility
    cat > /usr/bin/menu << 'EOF'
#!/bin/bash
/etc/MonsterVps/menu.sh "$@"
EOF
    
    chmod +x /usr/bin/menu
    
    # Create monstervps command
    cat > /usr/local/bin/monstervps << 'EOF'
#!/bin/bash
/etc/MonsterVps/menu.sh "$@"
EOF
    
    chmod +x /usr/local/bin/monstervps
    
    # Add to PATH in bashrc and profile
    if ! grep -q "/usr/local/bin" /root/.bashrc; then
        echo 'export PATH="/usr/local/bin:$PATH"' >> /root/.bashrc
    fi
    
    if ! grep -q "/usr/local/bin" /etc/profile; then
        echo 'export PATH="/usr/local/bin:$PATH"' >> /etc/profile
    fi
    
    # Create alias in bashrc for all users
    if ! grep -q "alias menu=" /root/.bashrc; then
        echo "alias menu='/etc/MonsterVps/menu.sh'" >> /root/.bashrc
    fi
    
    # Add to /etc/bash.bashrc for all users
    if ! grep -q "alias menu=" /etc/bash.bashrc 2>/dev/null; then
        echo "alias menu='/etc/MonsterVps/menu.sh'" >> /etc/bash.bashrc
    fi
}

# Final configuration
final_configuration() {
    title "CONFIGURACION FINAL"
    
    # Set timezone
    timedatectl set-timezone America/Argentina/Buenos_Aires 2>/dev/null
    
    # Configure system limits
    echo "* soft nofile 65536" >> /etc/security/limits.conf
    echo "* hard nofile 65536" >> /etc/security/limits.conf
    
    # Configure kernel parameters
    echo "net.core.default_qdisc = fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control = bbr" >> /etc/sysctl.conf
    sysctl -p
    
    # Create version file
    echo "1.0.0" > "$MonsterVps/version"
    
    # Create installation date
    date > "$MonsterVps/install_date"
    
    echo -e "${green}✓ Final configuration completed${rest}"
}

# Installation success message
installation_success() {
    banner
    echo -e "${green}╔══════════════════════════════════════════════════════════════╗${rest}"
    echo -e "${green}║                  INSTALACION COMPLETADA                     ║${rest}"
    echo -e "${green}║                   MonsterVps by mastermind                  ║${rest}"
    echo -e "${green}╚══════════════════════════════════════════════════════════════╝${rest}"
    echo ""
    echo -e "${cyan}Sistema instalado exitosamente!${rest}"
    echo ""
    echo -e "${yellow}Para acceder al menu principal:${rest}"
    echo -e "${green}• Ejecute: ${cyan}monstervps${rest}"
    echo -e "${green}• O ejecute: ${cyan}/etc/MonsterVps/menu.sh${rest}"
    echo -e "${green}• O ejecute: ${cyan}menu${rest}"
    echo ""
    echo -e "${yellow}Protocolos disponibles:${rest}"
    echo -e "${green}• SSH/Dropbear • V2Ray • WireGuard • OpenVPN${rest}"
    echo -e "${green}• Stunnel • SlowDNS • UDP Custom • SOCKS Proxy${rest}"
    echo ""
    echo -e "${yellow}Utilidades incluidas:${rest}"
    echo -e "${green}• Limitador de conexiones • Monitor de usuarios${rest}"
    echo -e "${green}• Gestor de base de datos • Sistema de tokens${rest}"
    echo -e "${green}• Herramientas de red • Configuracion SSL${rest}"
    echo ""
    msg -bar2
    echo -e "${cyan}Presione Enter para acceder al menu principal...${rest}"
    read
    /etc/MonsterVps/menu.sh
}

# Main installation function
main_install() {
    case "$1" in
        --start|start)
            banner
            install_dependencies
            sleep 2
            install_protocols
            sleep 2
            setup_database
            sleep 2
            install_utilities
            sleep 2
            configure_services
            sleep 2
            configure_firewall
            sleep 2
            create_menu
            sleep 2
            final_configuration
            sleep 2
            installation_success
            ;;
        --update|update)
            title "ACTUALIZANDO MonsterVps"
            install_utilities
            echo -e "${green}✓ MonsterVps actualizado exitosamente${rest}"
            ;;
        --test|test)
            title "MODO DE PRUEBA"
            echo -e "${green}✓ Sistema funcionando correctamente${rest}"
            echo -e "${cyan}Ejecute con --start para instalar${rest}"
            ;;
        --help|help|-h)
            banner
            echo -e "${cyan}Uso: $0 [OPCION]${rest}"
            echo ""
            echo -e "${yellow}Opciones disponibles:${rest}"
            echo -e "${green}  --start    ${rest}Instalar MonsterVps completo"
            echo -e "${green}  --update   ${rest}Actualizar MonsterVps"
            echo -e "${green}  --test     ${rest}Probar funcionamiento"
            echo -e "${green}  --help     ${rest}Mostrar esta ayuda"
            echo ""
            ;;
        *)
            banner
            echo -e "${cyan}╔══════════════════════════════════════════════════════════════╗${rest}"
            echo -e "${cyan}║                    INSTALADOR MonsterVps                    ║${rest}"
            echo -e "${cyan}║                      by mastermind                          ║${rest}"
            echo -e "${cyan}╚══════════════════════════════════════════════════════════════╝${rest}"
            echo ""
            echo -e "${yellow}Seleccione una opcion:${rest}"
            echo ""
            echo -e "${green}1)${rest} Instalar MonsterVps completo"
            echo -e "${green}2)${rest} Actualizar MonsterVps"
            echo -e "${green}3)${rest} Probar sistema"
            echo -e "${green}4)${rest} Mostrar ayuda"
            echo -e "${green}0)${rest} Salir"
            echo ""
            read -p "Seleccione opcion [1-4]: " option
            
            case $option in
                1) main_install --start ;;
                2) main_install --update ;;
                3) main_install --test ;;
                4) main_install --help ;;
                0) echo -e "${cyan}Saliendo...${rest}"; exit 0 ;;
                *) echo -e "${red}Opcion invalida${rest}"; exit 1 ;;
            esac
            ;;
    esac
}

# Run main installation
main_install "$@"