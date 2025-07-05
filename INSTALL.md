# MonsterVps Installation Guide

## Quick Installation (Recommended)

### One-Command Installation
```bash
wget https://raw.githubusercontent.com/mafiadan6/MonsterVps/master/install.sh && chmod +x install.sh && sudo ./install.sh
```

### Alternative Quick Install
```bash
curl -sL https://raw.githubusercontent.com/mafiadan6/MonsterVps/master/install.sh | sudo bash
```

## Complete Installation

### Method 1: Clone and Install
```bash
# Clone the repository
git clone https://github.com/mafiadan6/MonsterVps.git
cd MonsterVps

# Run the complete installer
sudo ./complete_install.sh --start
```

### Method 2: Download and Install
```bash
# Download the installer
wget https://raw.githubusercontent.com/mafiadan6/MonsterVps/master/complete_install.sh
chmod +x complete_install.sh

# Run installation
sudo ./complete_install.sh --start
```

## Post-Installation Access

After successful installation, you can access MonsterVps using any of these methods:

### Method 1: Direct Command (Recommended)
```bash
menu
```

### Method 2: Alternative Command
```bash
monstervps
```

### Method 3: Full Path
```bash
/etc/MonsterVps/menu.sh
```

## Installation Options

### Start Full Installation
```bash
sudo ./complete_install.sh --start
```

### Update MonsterVps
```bash
sudo ./complete_install.sh --update
```

### Test Installation
```bash
sudo ./complete_install.sh --test
```

### Show Help
```bash
sudo ./complete_install.sh --help
```

## System Requirements

### Minimum Requirements
- **OS**: Ubuntu 18.04+ / Debian 9+ / CentOS 7+
- **RAM**: 512MB (1GB recommended)
- **Storage**: 2GB free space
- **Network**: Internet connection
- **Access**: Root privileges

### Recommended Requirements
- **CPU**: 2+ cores
- **RAM**: 2GB+
- **Storage**: 10GB+ free space
- **Network**: 100Mbps+ connection

## Supported Operating Systems

### Ubuntu
- Ubuntu 18.04 LTS
- Ubuntu 20.04 LTS
- Ubuntu 22.04 LTS

### Debian
- Debian 9 (Stretch)
- Debian 10 (Buster)
- Debian 11 (Bullseye)

### CentOS
- CentOS 7
- CentOS 8
- CentOS Stream

## Installation Process

The installation process includes:

1. **Dependency Installation**: Automatic installation of required packages
2. **Protocol Setup**: Configuration of all VPN protocols
3. **Database Setup**: SQLite database initialization
4. **Utility Installation**: All management tools and utilities
5. **Service Configuration**: Systemd service setup
6. **Firewall Configuration**: Automatic firewall rules
7. **Menu Creation**: Global menu command setup
8. **Final Configuration**: System optimization and setup

## What Gets Installed

### Core Components
- MonsterVps management system
- Multi-protocol VPN support
- User management database
- Connection monitoring system
- Token authentication system

### Protocols
- **SSH**: Secure Shell with management
- **V2Ray**: Advanced proxy protocol
- **WireGuard**: Modern VPN protocol
- **OpenVPN**: Traditional VPN protocol
- **Stunnel**: SSL tunneling
- **Dropbear**: Lightweight SSH
- **SlowDNS**: DNS tunneling
- **UDP Custom**: Custom UDP protocols
- **SOCKS**: Proxy protocol support

### Management Tools
- User creation and management
- Connection limiting system
- Real-time monitoring
- Database management
- Port management
- SSL certificate handling
- Traffic optimization
- System monitoring

## Troubleshooting

### Common Issues

#### Permission Denied
```bash
sudo chmod +x install.sh
sudo ./install.sh
```

#### Network Issues
```bash
# Check internet connection
ping -c 3 google.com

# Check DNS resolution
nslookup github.com
```

#### Space Issues
```bash
# Check available space
df -h

# Clean up if needed
sudo apt autoremove
sudo apt autoclean
```

### Installation Logs
Check installation logs at:
- `/var/log/monstervps.log`
- `/var/log/syslog`
- `/var/log/auth.log`

## Verification

After installation, verify the system:

```bash
# Check if menu command works
menu

# Check system status
systemctl status ssh
systemctl status v2ray

# Check database
sqlite3 /etc/MonsterVps/db/users.db ".tables"

# Check services
ss -tlnp | grep -E "(22|80|443|1194|51820)"
```

## Uninstallation

To remove MonsterVps:

```bash
sudo /etc/MonsterVps/uninstall.sh
```

Or manually:

```bash
# Stop services
sudo systemctl stop ssh v2ray openvpn@*

# Remove files
sudo rm -rf /etc/MonsterVps
sudo rm -f /usr/local/bin/menu
sudo rm -f /usr/local/bin/monstervps
sudo rm -f /usr/bin/menu

# Remove aliases
sudo sed -i '/alias menu=/d' /root/.bashrc
sudo sed -i '/alias menu=/d' /etc/bash.bashrc
```

## Support

For support and troubleshooting:

- **GitHub Issues**: https://github.com/mafiadan6/MonsterVps/issues
- **Documentation**: README.md
- **Community**: GitHub Discussions
- **Telegram**: @MonsterVps_bot

## License

MIT License - see LICENSE file for details.

---

**Made with ❤️ by mastermind**