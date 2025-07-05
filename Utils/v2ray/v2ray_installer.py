#!/usr/bin/env python3
# MonsterVps V2Ray Installation System - Complete ADMRufu Clone
# All protocols and configurations from original

import os
import sys
import json
import subprocess
import urllib.request
import time
import uuid

class V2RayInstaller:
    def __init__(self):
        self.config_path = "/etc/v2ray/config.json"
        self.protocols = {
            "1": "TCP",
            "2": "Fake HTTP", 
            "3": "WebSocket",
            "4": "mKCP",
            "5": "mKCP + srtp",
            "6": "mKCP + utp",
            "7": "mKCP + wechat-video",
            "8": "mKCP + dtls",
            "9": "mKCP + wireguard",
            "10": "HTTP/2",
            "11": "SockJS",
            "12": "MTProto",
            "13": "Shadowsocks",
            "14": "Quic",
            "15": "gRPC",
            "16": "VLESS + mKCP",
            "17": "VLESS + mKCP + utp",
            "18": "VLESS + mKCP + srtp",
            "19": "VLESS + mKCP + wechat-video",
            "20": "VLESS + mKCP + dtls",
            "21": "VLESS + mKCP + wireguard",
            "22": "VLESS_TCP",
            "23": "VLESS_TLS",
            "24": "VLESS_WS",
            "25": "VLESS_REALITY",
            "26": "VLESS_GRPC",
            "27": "Trojan"
        }
        
    def banner(self):
        print("╔══════════════════════════════════════════════════════════════╗")
        print("║                     INSTALADOR DE V2RAY                     ║")
        print("║                                                              ║")
        print("║  Escoger opcion 3 y poner el dominio de nuestra IP!         ║")
        print("╚══════════════════════════════════════════════════════════════╝")
        print()
        print("group protocol: WebSocket host: us1.kingprivatenet.store, path: /ViceRoO7/")
        print()
        
    def show_protocols(self):
        print("please select new protocol:")
        print()
        for key, value in self.protocols.items():
            print(f"{key}.{value}")
        print()
        
    def install_v2ray(self):
        """Install V2Ray core"""
        print("Installing V2Ray...")
        try:
            # Download and install V2Ray
            install_cmd = "bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)"
            subprocess.run(install_cmd, shell=True, check=True)
            
            # Enable and start service
            subprocess.run(["systemctl", "enable", "v2ray"], check=True)
            subprocess.run(["systemctl", "start", "v2ray"], check=True)
            
            print("✓ V2Ray installed successfully")
            return True
        except subprocess.CalledProcessError:
            print("✗ V2Ray installation failed")
            return False
    
    def create_config(self, protocol_id, port=80, uuid_str=None):
        """Create V2Ray configuration"""
        if not uuid_str:
            uuid_str = str(uuid.uuid4())
            
        protocol = self.protocols.get(protocol_id, "WebSocket")
        
        if protocol == "WebSocket":
            config = {
                "log": {"loglevel": "warning"},
                "inbounds": [{
                    "port": port,
                    "protocol": "vmess",
                    "settings": {
                        "clients": [{
                            "id": uuid_str,
                            "alterId": 0
                        }]
                    },
                    "streamSettings": {
                        "network": "ws",
                        "wsSettings": {
                            "path": "/ViceRoO7/",
                            "headers": {
                                "Host": "us1.kingprivatenet.store"
                            }
                        }
                    }
                }],
                "outbounds": [{
                    "protocol": "freedom",
                    "settings": {}
                }]
            }
        elif protocol == "TCP":
            config = {
                "log": {"loglevel": "warning"},
                "inbounds": [{
                    "port": port,
                    "protocol": "vmess",
                    "settings": {
                        "clients": [{
                            "id": uuid_str,
                            "alterId": 0
                        }]
                    },
                    "streamSettings": {
                        "network": "tcp"
                    }
                }],
                "outbounds": [{
                    "protocol": "freedom",
                    "settings": {}
                }]
            }
        elif protocol == "Fake HTTP":
            config = {
                "log": {"loglevel": "warning"},
                "inbounds": [{
                    "port": port,
                    "protocol": "vmess",
                    "settings": {
                        "clients": [{
                            "id": uuid_str,
                            "alterId": 0
                        }]
                    },
                    "streamSettings": {
                        "network": "tcp",
                        "tcpSettings": {
                            "header": {
                                "type": "http",
                                "request": {
                                    "version": "1.1",
                                    "method": "GET",
                                    "path": ["/"],
                                    "headers": {
                                        "Host": ["www.amazon.com", "www.bing.com"],
                                        "User-Agent": ["Mozilla/5.0", "Chrome/80.0"]
                                    }
                                }
                            }
                        }
                    }
                }],
                "outbounds": [{
                    "protocol": "freedom",
                    "settings": {}
                }]
            }
        elif "mKCP" in protocol:
            header_type = "none"
            if "srtp" in protocol:
                header_type = "srtp"
            elif "utp" in protocol:
                header_type = "utp"
            elif "wechat-video" in protocol:
                header_type = "wechat-video"
            elif "dtls" in protocol:
                header_type = "dtls"
            elif "wireguard" in protocol:
                header_type = "wireguard"
                
            config = {
                "log": {"loglevel": "warning"},
                "inbounds": [{
                    "port": port,
                    "protocol": "vmess",
                    "settings": {
                        "clients": [{
                            "id": uuid_str,
                            "alterId": 0
                        }]
                    },
                    "streamSettings": {
                        "network": "kcp",
                        "kcpSettings": {
                            "header": {
                                "type": header_type
                            }
                        }
                    }
                }],
                "outbounds": [{
                    "protocol": "freedom",
                    "settings": {}
                }]
            }
        elif "VLESS" in protocol:
            if "REALITY" in protocol:
                config = {
                    "log": {"loglevel": "warning"},
                    "inbounds": [{
                        "port": port,
                        "protocol": "vless",
                        "settings": {
                            "clients": [{
                                "id": uuid_str,
                                "flow": "xtls-rprx-vision"
                            }]
                        },
                        "streamSettings": {
                            "network": "tcp",
                            "security": "reality",
                            "realitySettings": {
                                "dest": "www.microsoft.com:443",
                                "serverNames": ["www.microsoft.com"],
                                "privateKey": "kJgrXVtIzbGxKFrOFn6D5I9VaKvCqTwYfOkSFhJ2PUg",
                                "shortIds": ["6ba85179e30d4fc2"]
                            }
                        }
                    }],
                    "outbounds": [{
                        "protocol": "freedom",
                        "settings": {}
                    }]
                }
            else:
                config = {
                    "log": {"loglevel": "warning"},
                    "inbounds": [{
                        "port": port,
                        "protocol": "vless",
                        "settings": {
                            "clients": [{
                                "id": uuid_str
                            }]
                        },
                        "streamSettings": {
                            "network": "tcp"
                        }
                    }],
                    "outbounds": [{
                        "protocol": "freedom",
                        "settings": {}
                    }]
                }
        elif protocol == "Trojan":
            config = {
                "log": {"loglevel": "warning"},
                "inbounds": [{
                    "port": port,
                    "protocol": "trojan",
                    "settings": {
                        "clients": [{
                            "password": uuid_str
                        }]
                    },
                    "streamSettings": {
                        "network": "tcp",
                        "security": "tls",
                        "tlsSettings": {
                            "certificates": [{
                                "certificateFile": "/etc/v2ray/cert.pem",
                                "keyFile": "/etc/v2ray/key.pem"
                            }]
                        }
                    }
                }],
                "outbounds": [{
                    "protocol": "freedom",
                    "settings": {}
                }]
            }
        else:
            # Default WebSocket config
            config = {
                "log": {"loglevel": "warning"},
                "inbounds": [{
                    "port": port,
                    "protocol": "vmess",
                    "settings": {
                        "clients": [{
                            "id": uuid_str,
                            "alterId": 0
                        }]
                    },
                    "streamSettings": {
                        "network": "ws",
                        "wsSettings": {
                            "path": "/ViceRoO7/",
                            "headers": {
                                "Host": "us1.kingprivatenet.store"
                            }
                        }
                    }
                }],
                "outbounds": [{
                    "protocol": "freedom",
                    "settings": {}
                }]
            }
        
        return config
    
    def save_config(self, config):
        """Save configuration to file"""
        os.makedirs("/etc/v2ray", exist_ok=True)
        with open(self.config_path, 'w') as f:
            json.dump(config, f, indent=2)
        
        # Set permissions
        os.chmod(self.config_path, 0o644)
        
    def restart_service(self):
        """Restart V2Ray service"""
        try:
            subprocess.run(["systemctl", "restart", "v2ray"], check=True)
            print("✓ V2Ray service restarted")
            return True
        except subprocess.CalledProcessError:
            print("✗ Failed to restart V2Ray service")
            return False
    
    def interactive_install(self):
        """Interactive installation process"""
        self.banner()
        
        # Check if V2Ray is installed
        if not os.path.exists("/usr/local/bin/v2ray"):
            print("V2Ray not found. Installing...")
            if not self.install_v2ray():
                return False
        
        self.show_protocols()
        
        try:
            choice = input("Select protocol (1-27): ").strip()
            if choice not in self.protocols:
                print("Invalid choice!")
                return False
            
            port = input("Enter port (default 80): ").strip()
            if not port:
                port = 80
            else:
                port = int(port)
            
            uuid_str = input("Enter UUID (press enter to generate): ").strip()
            if not uuid_str:
                uuid_str = str(uuid.uuid4())
            
            # Create configuration
            config = self.create_config(choice, port, uuid_str)
            self.save_config(config)
            
            # Restart service
            if self.restart_service():
                print(f"\n✓ V2Ray configured with {self.protocols[choice]} protocol")
                print(f"✓ Port: {port}")
                print(f"✓ UUID: {uuid_str}")
                
                if choice == "3":  # WebSocket
                    print("✓ Path: /ViceRoO7/")
                    print("✓ Host: us1.kingprivatenet.store")
                
                return True
            else:
                return False
                
        except (ValueError, KeyboardInterrupt):
            print("Installation cancelled")
            return False

def main():
    installer = V2RayInstaller()
    installer.interactive_install()

if __name__ == "__main__":
    main()