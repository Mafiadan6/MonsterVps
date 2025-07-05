# MonsterVps by mastermind

<div align="center">
  <h1>🚀 MonsterVps - Advanced VPN Management System</h1>
  <p><strong>The Ultimate Multi-Protocol VPN & Proxy Management Solution</strong></p>
  
  [![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
  [![Linux](https://img.shields.io/badge/OS-Linux-green.svg)](https://www.linux.org/)
  [![Bash](https://img.shields.io/badge/Shell-Bash-red.svg)](https://www.gnu.org/software/bash/)
  [![Version](https://img.shields.io/badge/Version-1.0.0-orange.svg)](https://github.com/mafiadan6/MonsterVps)
</div>

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Supported Protocols](#supported-protocols)
- [System Requirements](#system-requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
- [Advanced Features](#advanced-features)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)
- [Support](#support)

## 🎯 Overview

MonsterVps is a comprehensive VPN management script designed for Linux servers, providing a complete solution for managing multiple VPN protocols, user authentication, and system configuration through an intuitive command-line interface. Built with security, performance, and ease of use in mind.

### Key Highlights

- **Multi-Protocol Support**: SSH, V2Ray, WireGuard, OpenVPN, Stunnel, UDP protocols, and more
- **Advanced User Management**: Connection limiting, monitoring, and authentication
- **Token-Based Authentication**: Secure HWID verification and real-time validation
- **Interactive Interface**: User-friendly command-line menus
- **Automated Installation**: One-command setup with dependency management
- **Production Ready**: Designed for high-performance VPN services

## ✨ Features

### 🔐 Security Features
- **Token Authentication System**: Real-time online validation with HWID verification
- **Connection Limiting**: Configurable simultaneous connection limits per user
- **Firewall Integration**: Automatic iptables rule management
- **SSL Certificate Handling**: Automatic certificate generation and management
- **Encrypted Communications**: Secure channels for all sensitive operations

### 🛠️ Management Tools
- **User Database**: SQLite-based user management with expiration control
- **Real-time Monitoring**: Connection and bandwidth monitoring
- **Service Management**: Systemd integration for all services
- **Backup & Restore**: Configuration backup and recovery system
- **Update System**: Automatic updates from GitHub repository

### 🌐 Network Features
- **Multi-Protocol Support**: Unified interface for different VPN protocols
- **Dynamic Port Management**: Automatic port configuration
- **Traffic Optimization**: BBR congestion control and kernel optimization
- **DNS Management**: Custom DNS configuration including SlowDNS

## 🔧 Supported Protocols

| Protocol | Port | Status | Description |
|----------|------|--------|-------------|
| **SSH** | 22 | ✅ | Secure Shell with connection management |
| **V2Ray** | 443, 80 | ✅ | Advanced proxy with multiple transport protocols |
| **WireGuard** | 51820 | ✅ | Modern VPN with superior performance |
| **OpenVPN** | 1194 | ✅ | Traditional VPN with wide compatibility |
| **Stunnel** | 443 | ✅ | SSL tunnel for encrypted connections |
| **Dropbear** | 109, 143 | ✅ | Lightweight SSH server |
| **SlowDNS** | 5300 | ✅ | DNS-based tunneling protocol |
| **UDP Custom** | Various | ✅ | Custom UDP protocols (Request, Hysteria) |
| **SOCKS Proxy** | 1080 | ✅ | SOCKS4/5 proxy support |

## 📋 System Requirements

### Minimum Requirements
- **Operating System**: Ubuntu 18.04+ / Debian 9+ / CentOS 7+
- **Memory**: 512MB RAM (1GB recommended)
- **Storage**: 2GB free space
- **Network**: Internet connection for installation and updates
- **Privileges**: Root access required

### Recommended Setup
- **CPU**: 2+ cores
- **Memory**: 2GB+ RAM
- **Storage**: 10GB+ free space
- **Network**: 100Mbps+ connection

### Supported Distributions
- Ubuntu 18.04, 20.04, 22.04
- Debian 9, 10, 11
- CentOS 7, 8
- Other systemd-based distributions

## 🚀 Installation

### Quick Installation (Recommended)

```bash
# Download and run the installer
wget https://raw.githubusercontent.com/mafiadan6/MonsterVps/master/install.sh
chmod +x install.sh
sudo ./install.sh
```

### Complete Installation

```bash
# Clone the repository
git clone https://github.com/mafiadan6/MonsterVps.git
cd MonsterVps

# Run the complete installer
sudo ./complete_install.sh --start
```

### One-Line Installation

```bash
curl -sL https://raw.githubusercontent.com/mafiadan6/MonsterVps/master/install.sh | sudo bash
```

## 🎮 Usage

### Accessing the Menu

After installation, you can access the MonsterVps menu using any of these methods:

```bash
# Method 1: Direct command
menu

# Method 2: Full command
monstervps

# Method 3: Direct path
/etc/MonsterVps/menu.sh
```

### Main Menu Options

```
╔══════════════════════════════════════════════════════════════╗
║                        MonsterVps                            ║
║                  Advanced VPN Manager                        ║
║                     by mastermind                           ║
╚══════════════════════════════════════════════════════════════╝

1) SSH/Dropbear Management
2) V2Ray Configuration
3) WireGuard Setup
4) OpenVPN Management
5) Stunnel Configuration
6) UDP Protocols
7) User Management
8) System Monitor
9) Network Tools
10) System Configuration
0) Exit
```

### Common Commands

```bash
# Install MonsterVps
sudo ./complete_install.sh --start

# Update MonsterVps
sudo ./complete_install.sh --update

# Test installation
sudo ./complete_install.sh --test

# Access help
sudo ./complete_install.sh --help
```

## ⚙️ Configuration

### User Management

```bash
# Create new SSH user
/etc/MonsterVps/Utils/user-manager/create-user.sh

# Monitor active connections
/etc/MonsterVps/Utils/user-monitor.sh

# Manage connection limits
/etc/MonsterVps/Utils/limitador.sh
```

### Protocol Configuration

```bash
# Configure V2Ray
/etc/MonsterVps/Utils/v2ray/v2ray.py

# Setup WireGuard
/etc/MonsterVps/Utils/wireguard/wireguard.sh

# Configure OpenVPN
/etc/MonsterVps/Utils/openvpn/openvpn.sh
```

### Database Management

```bash
# Manage user database
/etc/MonsterVps/Utils/database-manager.sh

# View user statistics
sqlite3 /etc/MonsterVps/db/users.db "SELECT * FROM ssh_users;"
```

## 🔥 Advanced Features

### Token Authentication System

MonsterVps includes an advanced token-based authentication system:

```bash
# Generate authentication token
/etc/MonsterVps/Utils/aToken/aToken.py

# Validate user token
/etc/MonsterVps/Utils/aToken/validate-token.sh
```

### Connection Limiting

Advanced connection limiting with real-time monitoring:

```bash
# Set user connection limit
/etc/MonsterVps/Utils/limitador.sh set-limit username 5

# Monitor connections
/etc/MonsterVps/Utils/user-monitor.sh status
```

### Traffic Optimization

Built-in traffic optimization features:

```bash
# Enable BBR congestion control
echo 'net.core.default_qdisc = fq' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_congestion_control = bbr' >> /etc/sysctl.conf
sysctl -p
```

## 🛠️ Troubleshooting

### Common Issues

#### Installation Problems

```bash
# Check system requirements
cat /etc/os-release

# Verify internet connection
ping -c 3 google.com

# Check available space
df -h
```

#### Service Issues

```bash
# Check service status
systemctl status ssh
systemctl status v2ray
systemctl status wg-quick@wg0

# View logs
journalctl -u ssh -f
journalctl -u v2ray -f
```

#### Permission Issues

```bash
# Fix permissions
sudo chown -R root:root /etc/MonsterVps
sudo chmod -R 755 /etc/MonsterVps
sudo chmod +x /etc/MonsterVps/menu.sh
```

### Log Files

```bash
# System logs
tail -f /var/log/monstervps.log

# Service logs
tail -f /var/log/auth.log
tail -f /var/log/syslog
```

## 🤝 Contributing

We welcome contributions to MonsterVps! Please follow these guidelines:

### How to Contribute

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Setup

```bash
# Clone the repository
git clone https://github.com/mafiadan6/MonsterVps.git
cd MonsterVps

# Set up development environment
./dev-setup.sh
```

### Code Style

- Use 4-space indentation
- Follow bash best practices
- Add comments for complex logic
- Test all changes before submitting

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

### Getting Help

- **Documentation**: Check this README and the [Wiki](https://github.com/mafiadan6/MonsterVps/wiki)
- **Issues**: Report bugs on [GitHub Issues](https://github.com/mafiadan6/MonsterVps/issues)
- **Discussions**: Join [GitHub Discussions](https://github.com/mafiadan6/MonsterVps/discussions)

### Community

- **Telegram**: [@MonsterVps_bot](https://t.me/MonsterVps_bot)
- **Discord**: [MonsterVps Community](https://discord.gg/monstervps)
- **Reddit**: [r/MonsterVps](https://reddit.com/r/MonsterVps)

### Professional Support

For professional support, custom installations, or enterprise solutions, contact us at:
- **Email**: support@monstervps.com
- **Website**: [https://monstervps.com](https://monstervps.com)

---

<div align="center">
  <p><strong>Made with ❤️ by mastermind</strong></p>
  <p>© 2025 MonsterVps. All rights reserved.</p>
</div>