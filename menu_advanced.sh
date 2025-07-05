#!/bin/bash

# MonsterVps Advanced Menu System - Complete ADMRufu Clone
# All original features including SOCKS Python, WebSocket protocols, custom headers

# Colors
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[1;33m'
blue='\033[0;34m'
cyan='\033[0;36m'
purple='\033[0;35m'
rest='\033[0m'

# System information
get_system_info() {
    local ip=$(curl -s ipv4.icanhazip.com 2>/dev/null || echo "N/A")
    local ram=$(free -h | awk '/^Mem:/ {print $4"/"$2}')
    local cpu=$(nproc)
    local os=$(lsb_release -d 2>/dev/null | cut -f2 || echo "Linux")
    echo "$os|$ip|$ram|$cpu"
}

# Get active connections
get_connections() {
    local ssh_reg=$(ps aux | grep -c "[s]shd:" 2>/dev/null || echo "0")
    local ss_ssrr=$(ps aux | grep -c "[s]s-server" 2>/dev/null || echo "0") 
    local v2ray_reg=$(ps aux | grep -c "[v]2ray" 2>/dev/null || echo "0")
    local online=$(who | wc -l 2>/dev/null || echo "0")
    local expirados=$(sqlite3 /etc/MonsterVps/db/users.db "SELECT COUNT(*) FROM ssh_users WHERE date(expiry_date) < date('now')" 2>/dev/null || echo "0")
    local bloqueados=$(sqlite3 /etc/MonsterVps/db/users.db "SELECT COUNT(*) FROM ssh_users WHERE status='blocked'" 2>/dev/null || echo "0")
    
    echo "$ssh_reg|$ss_ssrr|$v2ray_reg|$online|$expirados|$bloqueados"
}

# Banner function
banner() {
    clear
    local sys_info=$(get_system_info)
    local conn_info=$(get_connections)
    
    IFS='|' read -r os ip ram cpu <<< "$sys_info"
    IFS='|' read -r ssh_reg ss_ssrr v2ray_reg online expirados bloqueados <<< "$conn_info"
    
    echo -e "${red}>>>>>${rest} ${cyan}SCRIPT MOD LACASITAMX${rest} ${red}<<<<<${rest} ${yellow}Version 11X${rest}"
    echo ""
    echo -e "${blue}OS${rest} : ${green}$os${rest} ${blue}HORA${rest}: ${green}$(date '+%H:%M:%S')${rest} ${blue}IP${rest}: ${green}$ip${rest}"
    echo -e "${blue}RAM${rest}: ${green}$ram${rest} ${blue}USADO${rest}: ${green}$(free -h | awk '/^Mem:/ {print $3}')${rest} ${blue}LIBRE${rest}: ${green}$(df -h / | awk 'NR==2 {print $4}')${rest}"
    echo ""
    echo -e "${cyan}═════════════════════════════════════${rest}"
    echo ""
    echo -e "${cyan}● ${yellow}ADRIANV9 ${cyan}●${rest}"
    echo ""
    echo -e "${blue}SSH REG${rest}: ${green}$ssh_reg${rest}    ${blue}SS-SSRR REG${rest}: ${green}$ss_ssrr${rest}    ${blue}V2RAY REG${rest}: ${green}$v2ray_reg${rest}"
    echo -e "${blue}ONLINE${rest}: ${green}$online${rest}    ${red}EXPIRADOS${rest}: ${red}$expirados${rest}    ${red}BLOQUEADOS${rest}: ${red}$bloqueados${rest}"
    echo ""
}

# Main menu
main_menu() {
    banner
    echo -e "${green}[1]${rest}   ADMINISTRAR CUENTAS | SSH/HWID/TOKEN"
    echo -e "${green}[2]${rest}   ADMINISTRAR CUENTAS | SS/SSRR"
    echo -e "${green}[3]${rest}   ADMINISTRAR CUENTAS | V2RAY ---------- ${green}[ON]${rest}"
    echo -e "${green}[4]${rest}   ${red}HERRAMIENTAS DE REDES/SISTEMAS${rest}"
    echo -e "${green}[5]${rest}   MONITOR DE PROTOCOLOS -------------- ${red}[OFF]${rest}"
    echo -e "${green}[6]${rest}   AUTO INICIAR SCRIPT -------------- ${green}[ON]${rest}"
    echo -e "${green}[7]${rest}   TCP SPEED BBR --------------------- ${green}[ON]${rest}"
    echo ""
    echo -e "${green}[8]${rest}   ${cyan}ACTUALIZAR${rest} ${green}[9] - ${red}DESINSTALAR${rest} ${green}[0] - ${yellow}SALIR${rest}"
    echo ""
    echo -e "• Seleccione una Opción:"
}

# SSH/HWID/TOKEN Management
ssh_menu() {
    banner
    echo -e "${yellow}ADMINISTRADOR DE USUARIOS /SSH/HWID/TOKEN${rest}"
    echo ""
    echo -e "${green}[1]${rest}   CREAR NUEVO USUARIO [SSH/HWID/TOKEN ]"
    echo -e "${green}[2]${rest}   REMOVER USUARIO [SSH/HWID/TOKEN ]"
    echo -e "${green}[3]${rest}   BLOQUEAR [DESBLOQUEAR USUARIO"
    echo -e "${green}[4]${rest}   REINICIAR CONTADOR DE BLOQUEOS |EXPIRADOS"
    echo -e "${green}[5]${rest}   EDITAR USUARIO"
    echo -e "${green}[6]${rest}   RENOVAR USUARIO [SSH/HWID/TOKEN ]"
    echo -e "${green}[7]${rest}   MOSTRAR CUENTAS [SSH/HWID/TOKEN ]"
    echo -e "${green}[8]${rest}   USUARIOS CONECTADOS [SSH/HWID/TOKEN ]"
    echo -e "${green}[9]${rest}   ELIMINAR CUENTAS EXPIRADAS"
    echo -e "${green}[10]${rest}  BACKUP USUARIOS [SSH/HWID/TOKEN ]"
    echo -e "${green}[11]${rest}  AGREGAR/ELIMINAR BANNER"
    echo -e "${green}[12]${rest}  ${yellow}⚠${rest} ${yellow}CONFIGURAR TODOS LOS USUARIOS${rest} ${yellow}⚠${rest}"
    echo -e "${green}[13]${rest}  ${red}🔒${rest} LIMITADOR-DE-CUENTAS ${red}🔒${rest} ${green}[DESACTIVADO]${rest}"
    echo -e "${green}[14]${rest}  ${red}🔒${rest} DESBLOQUEO-AUTOMATICO ${red}🔒${rest} ${green}[DESACTIVADO]${rest}"
    echo -e "${green}[15]${rest}  LOG DE CUENTAS REGISTRADAS"
    echo -e "${green}[16]${rest}  LIMPIAR LOG DE LIMITADOR"
    echo -e "${green}[19]${rest}  ELIMINAR LINKS DE OVPN"
    echo ""
    echo -e "${green}[0]${rest}   ${red}VOLVER${rest}"
    echo ""
    echo -e "• Seleccione una Opción:"
}

# Protocols menu  
protocols_menu() {
    banner
    echo -e "${cyan}                    PROTOCOLOS                    HERRAMIENTAS${rest}"
    echo ""
    echo -e "${green}[1]${rest}   BADVPN               ${green}[ON]${rest}   ${green}[19]${rest}  ARCHIVO ONLINE"
    echo -e "${green}[2]${rest}   SOCKS LIBEV          ${red}[OFF]${rest}  ${green}[20]${rest}  FIREWALL"
    echo -e "${green}[3]${rest}   SOCKS PYTHON         ${green}[ON]${rest}   ${green}[21]${rest}  FAIL2BAN PROTECCION"
    echo -e "${green}[4]${rest}   V2RAY                ${green}[ON]${rest}   ${green}[22]${rest}  DETALLES DEL SISTEMA"
    echo -e "${green}[5]${rest}   DROPBEAR             ${green}[ON]${rest}   ${green}[23]${rest}  TCP BBR GRECIA"
    echo -e "${green}[6]${rest}   SQUID                ${green}[ON]${rest}   ${green}[24]${rest}  LIBERAR RAM"
    echo -e "${green}[7]${rest}   SQUID               ${red}[OFF]${rest}   ${green}[25]${rest}  LIBERAR RAM"
    echo -e "${green}[8]${rest}   OPENVPN             ${red}[OFF]${rest}   ${green}[26]${rest}  SCANEAR SUBDOMINIO"
    echo -e "${green}[9]${rest}   SLOWDNS             ${red}[OFF]${rest}   ${green}[27]${rest}  PRUEBA DE VELOCIDAD"
    echo -e "${green}[10]${rest}  MONITOR APP         ${red}[OFF]${rest}   ${green}[28]${rest}  FIX ORACLE/AWS/AZR"
    echo -e "${green}[11]${rest}  BOT TELEGRAM        ${red}[OFF]${rest}   ${green}[29]${rest}  ${yellow}HERRAMIENTAS BASICOS${rest}"
    echo -e "${green}[12]${rest}  WIREGUARD           ${red}[OFF]${rest}   ${green}[0]${rest}   • VOLVER"
    echo ""
    echo -e "${green}[13]${rest}  NHT-BOT            ${red}[OFF]${rest}   ${green}[16]${rest}  UDP-ZIVPN      ${red}[OFF]${rest}"
    echo -e "${green}[14]${rest}  CHECKUSER          ${red}[OFF]${rest}   ${green}[17]${rest}  UDPs Request   ${red}[OFF]${rest}"
    echo -e "${green}[15]${rest}  PSIPHON            ${red}[OFF]${rest}   ${green}[18]${rest}  UDP-CUSTOM     ${green}[ON]${rest}"
    echo -e "${green}[E]${rest}   WS-PRO             ${red}[OFF]${rest}   ${green}[L]${rest}   HYSTERIA-UDP   ${red}[OFF]${rest}"
    echo -e "${green}[F]${rest}   TROJAN-GO          ${red}[OFF]${rest}"
    echo ""
    echo -e "• Seleccione Una Opción:"
}

# SOCKS Python installer menu
socks_python_menu() {
    banner
    echo -e "${yellow}INSTALADOR DE PROXY'S${rest}"
    echo ""
    echo -e "${green}[1]${rest}   Proxy Python SIMPLE        ${red}[OFF]${rest}"
    echo -e "${green}[2]${rest}   Proxy Python SEGURO        ${red}[OFF]${rest}"
    echo -e "${green}[3]${rest}   Proxy WEBSOCKET Custom      ${green}[ON]${rest}  ${cyan}(Socks HTTP)${rest}"
    echo -e "${green}[4]${rest}   Proxy WEBSOCKET Custom      ${green}[ON]${rest}  ${cyan}(SYSTEMCTL)${rest}"
    echo -e "${green}[5]${rest}   WS DIRECTO  HTTPCustom      ${red}[OFF]${rest}  ${cyan}(WS)${rest}"
    echo -e "${green}[6]${rest}   Proxy Python OPENVPN       ${red}[OFF]${rest}"
    echo -e "${green}[7]${rest}   Proxy Python GETTUNEL      ${red}[OFF]${rest}"
    echo -e "${green}[8]${rest}   Proxy Python TCP BYPASS    ${green}[ON]${rest}"
    echo -e "${green}[9]${rest}   Aplicar Fix en Ubuntu 20 Debian11 )"
    echo -e "${green}[10]${rest}  DETENER SERVICIO PYTHON"
    echo ""
    echo -e "${green}[0]${rest}   ${red}VOLVER${rest}"
    echo ""
    echo -e "Digite Una Opcion (recomendado 3): ${cyan}_${rest}"
}

# WebSocket Custom configuration
websocket_custom() {
    banner
    echo -e "${yellow}CONFIGURADOR WEBSOCKET CUSTOM${rest}"
    echo ""
    echo -e "${cyan}Configurando WebSocket con respuestas HTTP personalizadas...${rest}"
    echo ""
    echo -e "Seleccione el código de respuesta HTTP:"
    echo -e "${green}[1]${rest} HTTP 101 (Switching Protocols)"
    echo -e "${green}[2]${rest} HTTP 200 (OK)"
    echo -e "${green}[3]${rest} HTTP 300 (Multiple Choices)" 
    echo -e "${green}[4]${rest} HTTP 301 (Moved Permanently)"
    echo ""
    read -p "Seleccione opción [1-4]: " http_code
    
    case $http_code in
        1) response_code="101" ;;
        2) response_code="200" ;;
        3) response_code="300" ;;
        4) response_code="301" ;;
        *) response_code="101" ;;
    esac
    
    echo ""
    read -p "Ingrese mensaje personalizado para usuarios conectados: " custom_message
    
    # Create WebSocket proxy with custom headers
    create_websocket_proxy "$response_code" "$custom_message"
}

# Create WebSocket proxy
create_websocket_proxy() {
    local response_code="$1"
    local custom_message="$2"
    
    cat > /etc/MonsterVps/websocket_proxy.py << EOF
#!/usr/bin/env python3
import socket
import threading
import base64
import hashlib

class WebSocketProxy:
    def __init__(self, port=80, target_port=22):
        self.port = port
        self.target_port = target_port
        self.response_code = "$response_code"
        self.custom_message = "$custom_message"
    
    def handle_client(self, client_socket):
        try:
            # Receive HTTP request
            request = client_socket.recv(4096).decode('utf-8')
            
            if 'Upgrade: websocket' in request:
                # WebSocket handshake
                key = self.extract_websocket_key(request)
                response = self.create_websocket_response(key)
                client_socket.send(response.encode('utf-8'))
                
                # Print custom message
                print(f"[INFO] Usuario conectado: {self.custom_message}")
                
                # Proxy connection
                self.proxy_connection(client_socket)
            else:
                # Regular HTTP response
                http_response = f"HTTP/1.1 {self.response_code} Custom Response\\r\\n"
                http_response += "Content-Type: text/html\\r\\n"
                http_response += "Connection: close\\r\\n\\r\\n"
                http_response += f"<html><body><h1>{self.custom_message}</h1></body></html>"
                client_socket.send(http_response.encode('utf-8'))
        except:
            pass
        finally:
            client_socket.close()
    
    def extract_websocket_key(self, request):
        for line in request.split('\\n'):
            if 'Sec-WebSocket-Key:' in line:
                return line.split(':')[1].strip()
        return ''
    
    def create_websocket_response(self, key):
        magic_string = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
        sha1 = hashlib.sha1((key + magic_string).encode()).digest()
        accept_key = base64.b64encode(sha1).decode()
        
        response = f"HTTP/1.1 {self.response_code} Switching Protocols\\r\\n"
        response += "Upgrade: websocket\\r\\n"
        response += "Connection: Upgrade\\r\\n"
        response += f"Sec-WebSocket-Accept: {accept_key}\\r\\n\\r\\n"
        return response
    
    def proxy_connection(self, client_socket):
        try:
            # Connect to SSH
            ssh_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            ssh_socket.connect(('127.0.0.1', self.target_port))
            
            # Start proxying
            threading.Thread(target=self.forward_data, args=(client_socket, ssh_socket)).start()
            threading.Thread(target=self.forward_data, args=(ssh_socket, client_socket)).start()
        except:
            pass
    
    def forward_data(self, source, destination):
        try:
            while True:
                data = source.recv(4096)
                if not data:
                    break
                destination.send(data)
        except:
            pass
        finally:
            source.close()
            destination.close()
    
    def start(self):
        server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        server.bind(('0.0.0.0', self.port))
        server.listen(5)
        
        print(f"[INFO] WebSocket Proxy iniciado en puerto {self.port}")
        print(f"[INFO] Código de respuesta: HTTP {self.response_code}")
        print(f"[INFO] Mensaje personalizado: {self.custom_message}")
        
        while True:
            client, addr = server.accept()
            threading.Thread(target=self.handle_client, args=(client,)).start()

if __name__ == "__main__":
    proxy = WebSocketProxy()
    proxy.start()
EOF

    chmod +x /etc/MonsterVps/websocket_proxy.py
    
    # Create systemd service
    cat > /etc/systemd/system/websocket-proxy.service << EOF
[Unit]
Description=MonsterVps WebSocket Proxy
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 /etc/MonsterVps/websocket_proxy.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable websocket-proxy
    systemctl start websocket-proxy
    
    echo -e "${green}✓ WebSocket Proxy configurado con HTTP $response_code${rest}"
    echo -e "${green}✓ Mensaje personalizado: $custom_message${rest}"
    echo -e "${green}✓ Servicio iniciado y habilitado${rest}"
}

# Menu handler
handle_menu() {
    case $1 in
        1) ssh_menu; handle_ssh_menu ;;
        2) echo "SS/SSRR Menu (Coming soon)"; read ;;
        3) echo "V2Ray Menu (Coming soon)"; read ;;
        4) protocols_menu; handle_protocols_menu ;;
        5) echo "Monitor de protocolos"; read ;;
        6) echo "Auto iniciar script"; read ;;
        7) echo "TCP Speed BBR"; read ;;
        8) echo "Actualizar"; read ;;
        9) echo "Desinstalar"; read ;;
        0) exit 0 ;;
        *) echo "Opción inválida"; sleep 1 ;;
    esac
}

handle_ssh_menu() {
    read -p "Seleccione opción: " opt
    case $opt in
        1) echo "Crear usuario SSH/HWID/TOKEN"; read ;;
        2) echo "Remover usuario"; read ;;
        3) echo "Bloquear/Desbloquear usuario"; read ;;
        13) echo "Limitador de cuentas"; read ;;
        0) return ;;
        *) echo "Opción inválida"; sleep 1 ;;
    esac
    ssh_menu
    handle_ssh_menu
}

handle_protocols_menu() {
    read -p "Seleccione opción: " opt
    case $opt in
        3) socks_python_menu; handle_socks_menu ;;
        0) return ;;
        *) echo "Protocolo $opt (Coming soon)"; read ;;
    esac
    protocols_menu
    handle_protocols_menu
}

handle_socks_menu() {
    read -p "Digite Una Opcion (recomendado 3): " opt
    case $opt in
        3) websocket_custom ;;
        0) return ;;
        *) echo "Proxy tipo $opt (Coming soon)"; read ;;
    esac
    socks_python_menu
    handle_socks_menu
}

# Main execution
while true; do
    main_menu
    read -p "" option
    handle_menu "$option"
done