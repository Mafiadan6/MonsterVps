#!/usr/bin/env python3
# MonsterVps SOCKS Python System - Complete ADMRufu Clone
# Supports WebSocket, Custom HTTP headers (101, 200, 300, 301), and advanced proxy features

import socket
import threading
import struct
import base64
import hashlib
import json
import time
import sys
import os
from urllib.parse import urlparse

class SOCKSProxy:
    def __init__(self, config_file="/etc/MonsterVps/socks_config.json"):
        self.config = self.load_config(config_file)
        self.running = True
        
    def load_config(self, config_file):
        default_config = {
            "port": 1080,
            "ssh_port": 22,
            "http_response_code": 101,
            "custom_message": "MonsterVps Proxy Connected",
            "websocket_enabled": True,
            "socks_version": 5,
            "log_connections": True,
            "max_connections": 1000
        }
        
        try:
            if os.path.exists(config_file):
                with open(config_file, 'r') as f:
                    config = json.load(f)
                    default_config.update(config)
        except:
            pass
            
        return default_config
    
    def log(self, message):
        if self.config.get("log_connections", True):
            timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
            print(f"[{timestamp}] {message}")
    
    def create_websocket_response(self, key, response_code=101):
        """Create WebSocket handshake response with custom HTTP code"""
        magic_string = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
        sha1 = hashlib.sha1((key + magic_string).encode()).digest()
        accept_key = base64.b64encode(sha1).decode()
        
        status_messages = {
            101: "Switching Protocols",
            200: "OK", 
            300: "Multiple Choices",
            301: "Moved Permanently"
        }
        
        status_msg = status_messages.get(response_code, "Switching Protocols")
        
        response = f"HTTP/1.1 {response_code} {status_msg}\r\n"
        response += "Upgrade: websocket\r\n"
        response += "Connection: Upgrade\r\n"
        response += f"Sec-WebSocket-Accept: {accept_key}\r\n"
        response += f"X-MonsterVps-Message: {self.config['custom_message']}\r\n"
        response += "\r\n"
        
        return response
    
    def handle_http_request(self, client_socket, request):
        """Handle HTTP/WebSocket requests"""
        try:
            lines = request.split('\n')
            headers = {}
            
            for line in lines[1:]:
                if ':' in line:
                    key, value = line.split(':', 1)
                    headers[key.strip().lower()] = value.strip()
            
            # Check for WebSocket upgrade
            if (headers.get('upgrade', '').lower() == 'websocket' and 
                'websocket' in headers.get('connection', '').lower()):
                
                websocket_key = headers.get('sec-websocket-key', '')
                if websocket_key:
                    response = self.create_websocket_response(
                        websocket_key, 
                        self.config['http_response_code']
                    )
                    client_socket.send(response.encode())
                    
                    self.log(f"WebSocket connection established: {self.config['custom_message']}")
                    
                    # Start proxying to SSH
                    self.proxy_to_ssh(client_socket)
                    return True
            
            # Regular HTTP response
            http_response = f"HTTP/1.1 {self.config['http_response_code']} Custom Response\r\n"
            http_response += "Content-Type: text/html\r\n"
            http_response += "Connection: close\r\n"
            http_response += f"X-MonsterVps-Message: {self.config['custom_message']}\r\n"
            http_response += "\r\n"
            http_response += f"<html><body><h1>{self.config['custom_message']}</h1></body></html>"
            
            client_socket.send(http_response.encode())
            
        except Exception as e:
            self.log(f"HTTP request error: {e}")
        
        return False
    
    def handle_socks5(self, client_socket):
        """Handle SOCKS5 protocol"""
        try:
            # SOCKS5 greeting
            data = client_socket.recv(1024)
            if len(data) < 2 or data[0] != 0x05:
                return False
            
            # Send authentication not required
            client_socket.send(b'\x05\x00')
            
            # SOCKS5 request
            data = client_socket.recv(1024)
            if len(data) < 4 or data[0] != 0x05:
                return False
            
            cmd = data[1]
            if cmd == 0x01:  # CONNECT
                # Parse target address
                atyp = data[3]
                if atyp == 0x01:  # IPv4
                    addr = socket.inet_ntoa(data[4:8])
                    port = struct.unpack('>H', data[8:10])[0]
                elif atyp == 0x03:  # Domain name
                    addr_len = data[4]
                    addr = data[5:5+addr_len].decode()
                    port = struct.unpack('>H', data[5+addr_len:7+addr_len])[0]
                else:
                    # Send not supported
                    client_socket.send(b'\x05\x08\x00\x01\x00\x00\x00\x00\x00\x00')
                    return False
                
                # Connect to target (redirect to SSH)
                try:
                    target_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                    target_socket.connect(('127.0.0.1', self.config['ssh_port']))
                    
                    # Send success response
                    response = b'\x05\x00\x00\x01'
                    response += socket.inet_aton('127.0.0.1')
                    response += struct.pack('>H', self.config['ssh_port'])
                    client_socket.send(response)
                    
                    self.log(f"SOCKS5 connection: {addr}:{port} -> SSH:{self.config['ssh_port']}")
                    
                    # Start proxying
                    self.start_proxy_threads(client_socket, target_socket)
                    return True
                    
                except Exception as e:
                    # Send connection refused
                    client_socket.send(b'\x05\x05\x00\x01\x00\x00\x00\x00\x00\x00')
                    self.log(f"SOCKS5 connection failed: {e}")
                    return False
            
        except Exception as e:
            self.log(f"SOCKS5 error: {e}")
        
        return False
    
    def proxy_to_ssh(self, client_socket):
        """Proxy WebSocket connection to SSH"""
        try:
            ssh_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            ssh_socket.connect(('127.0.0.1', self.config['ssh_port']))
            
            self.start_proxy_threads(client_socket, ssh_socket)
            
        except Exception as e:
            self.log(f"SSH proxy error: {e}")
    
    def start_proxy_threads(self, client_socket, target_socket):
        """Start bidirectional proxy threads"""
        def forward_data(source, destination, direction):
            try:
                while self.running:
                    data = source.recv(4096)
                    if not data:
                        break
                    destination.send(data)
            except:
                pass
            finally:
                try:
                    source.close()
                    destination.close()
                except:
                    pass
        
        # Start forwarding threads
        thread1 = threading.Thread(target=forward_data, args=(client_socket, target_socket, "client->target"))
        thread2 = threading.Thread(target=forward_data, args=(target_socket, client_socket, "target->client"))
        
        thread1.daemon = True
        thread2.daemon = True
        
        thread1.start()
        thread2.start()
        
        # Wait for threads to finish
        thread1.join()
        thread2.join()
    
    def handle_client(self, client_socket, client_address):
        """Handle incoming client connection"""
        try:
            self.log(f"New connection from {client_address[0]}:{client_address[1]}")
            
            # Peek at first few bytes to determine protocol
            client_socket.settimeout(5.0)
            data = client_socket.recv(1024, socket.MSG_PEEK)
            
            if not data:
                return
            
            # Check if it's HTTP/WebSocket
            if data.startswith(b'GET ') or data.startswith(b'POST '):
                full_request = client_socket.recv(4096).decode('utf-8', errors='ignore')
                if self.handle_http_request(client_socket, full_request):
                    return  # WebSocket connection established
            
            # Check if it's SOCKS5
            elif len(data) >= 2 and data[0] == 0x05:
                if self.handle_socks5(client_socket):
                    return  # SOCKS5 connection established
            
            # Default: try as raw proxy
            else:
                self.proxy_to_ssh(client_socket)
                
        except socket.timeout:
            self.log(f"Connection timeout from {client_address[0]}")
        except Exception as e:
            self.log(f"Client handling error: {e}")
        finally:
            try:
                client_socket.close()
            except:
                pass
    
    def start_server(self):
        """Start the proxy server"""
        server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        
        try:
            server_socket.bind(('0.0.0.0', self.config['port']))
            server_socket.listen(self.config['max_connections'])
            
            self.log(f"MonsterVps SOCKS Proxy started on port {self.config['port']}")
            self.log(f"WebSocket enabled: {self.config['websocket_enabled']}")
            self.log(f"HTTP response code: {self.config['http_response_code']}")
            self.log(f"Custom message: {self.config['custom_message']}")
            self.log(f"SSH target port: {self.config['ssh_port']}")
            
            while self.running:
                try:
                    client_socket, client_address = server_socket.accept()
                    
                    # Handle in separate thread
                    client_thread = threading.Thread(
                        target=self.handle_client,
                        args=(client_socket, client_address)
                    )
                    client_thread.daemon = True
                    client_thread.start()
                    
                except socket.error:
                    if self.running:
                        self.log("Server socket error")
                    break
                except KeyboardInterrupt:
                    break
                    
        except Exception as e:
            self.log(f"Server error: {e}")
        finally:
            server_socket.close()
            self.log("Server stopped")
    
    def stop(self):
        """Stop the proxy server"""
        self.running = False

def create_config_file():
    """Create default configuration file"""
    config = {
        "port": 1080,
        "ssh_port": 22,
        "http_response_code": 101,
        "custom_message": "MonsterVps Proxy Connected - Welcome!",
        "websocket_enabled": True,
        "socks_version": 5,
        "log_connections": True,
        "max_connections": 1000
    }
    
    os.makedirs("/etc/MonsterVps", exist_ok=True)
    with open("/etc/MonsterVps/socks_config.json", 'w') as f:
        json.dump(config, f, indent=2)
    
    print("Configuration file created at /etc/MonsterVps/socks_config.json")

def main():
    if len(sys.argv) > 1:
        if sys.argv[1] == "config":
            create_config_file()
            return
        elif sys.argv[1] == "help":
            print("MonsterVps SOCKS Python Proxy")
            print("Usage:")
            print("  python3 socks_python_complete.py        - Start proxy server")
            print("  python3 socks_python_complete.py config - Create config file")
            print("  python3 socks_python_complete.py help   - Show this help")
            return
    
    # Create config if it doesn't exist
    if not os.path.exists("/etc/MonsterVps/socks_config.json"):
        create_config_file()
    
    # Start proxy server
    proxy = SOCKSProxy()
    
    try:
        proxy.start_server()
    except KeyboardInterrupt:
        print("\nShutting down...")
        proxy.stop()

if __name__ == "__main__":
    main()