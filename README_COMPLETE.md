# MonsterVps - Complete ADMRufu Clone
**Advanced VPN Management System by mastermind**

## 🚀 Complete System with All Features

MonsterVps is a comprehensive VPN management system that includes **ALL** features from the original ADMRufu, plus advanced enhancements. This is a complete clone with every protocol, tool, and management feature.

### ✅ What's Included (Complete Feature List)

#### **V2Ray System (Complete with 27 Protocols)**
- TCP, Fake HTTP, WebSocket
- mKCP (all variants: srtp, utp, wechat-video, dtls, wireguard)
- HTTP/2, SockJS, MTProto, Shadowsocks
- Quic, gRPC, VLESS (all variants)
- VLESS_REALITY, Trojan
- **Complete protocol selection menu** exactly like original
- User management with UUID system
- Advanced configuration options

#### **Advanced SOCKS Python System**
- WebSocket support with custom headers
- **Custom HTTP response codes**: 101, 200, 300, 301
- **Custom connection messages** for users
- SystemD service integration
- SOCKS5 protocol support
- Multiple proxy types (SIMPLE, SEGURO, WebSocket Custom, etc.)

#### **Complete Utils Components (All 15 from Original)**
- ✅ **dropBear** - Dropbear SSH management
- ✅ **Stunnel** - SSL tunnel configuration
- ✅ **SlowDNS** - DNS-based tunneling
- ✅ **badvpn** - BadVPN UDP gateway
- ✅ **protocolsUDP** - UDP protocol management
- ✅ **udp-custom** - Custom UDP protocols
- ✅ **udp-zivpn** - ZiVPN UDP support
- ✅ **psiphon** - Psiphon protocol
- ✅ **epro-ws** - Enterprise WebSocket
- ✅ **genCert** - SSL certificate generation
- ✅ **mine_port** - Port mining and management
- ✅ **banner** - Custom SSH banners
- ✅ **checkuser** - User verification system
- ✅ **aToken** - Token authentication
- ✅ **user-manager** - Advanced user management

#### **User Management System**
- **SSH/HWID/TOKEN** authentication
- SQLite database for user storage
- Connection limiting and monitoring
- User expiration management
- Real-time connection tracking
- Advanced user statistics

#### **Advanced Menu System**
- **User-friendly fancy menu** exactly like original
- Protocol status indicators (ON/OFF)
- Real-time system information
- Connection monitoring display
- Easy navigation between all features

## 🔧 Installation

### Single Command Installation
```bash
wget https://raw.githubusercontent.com/Mafiadan6/MonsterVps/main/install.sh && chmod +x install.sh && sudo ./install.sh
```

### What Happens During Installation
1. **System dependencies** installed automatically
2. **Complete directory structure** created
3. **All 27 V2Ray protocols** configured
4. **Advanced SOCKS system** with WebSocket support
5. **All Utils components** from original ADMRufu
6. **User management database** initialized
7. **Menu system** configured globally

## 📋 After Installation

### Access the System
```bash
menu
```
*Works from anywhere in the system - type `menu` from any directory*

### Navigation Guide

#### **Main Menu Options:**
1. **SSH/HWID/TOKEN Management** - Complete user system
2. **SS/SSRR Management** - Shadowsocks protocols  
3. **V2Ray Management** - All 27 protocols available
4. **Network Tools/Protocols** - All Utils components
5. **Protocol Monitoring** - Real-time status
6. **Auto-Start Scripts** - Service management
7. **TCP Speed BBR** - Network optimization

#### **V2Ray Configuration:**
- Menu → Option 3 → V2Ray Management
- Select from 27 available protocols
- Configure WebSocket with custom domains
- Set up TLS/SSL certificates
- Manage UUID users

#### **Advanced SOCKS Setup:**
- Menu → Option 4 → Protocols → SOCKS Python
- Choose WebSocket Custom (Option 3 - recommended)
- Configure HTTP response codes (101, 200, 300, 301)
- Set custom connection messages
- Enable SystemD service

## 🌟 Key Features

### **Exactly Like Original ADMRufu:**
✅ Same menu structure and navigation  
✅ All protocol options and configurations  
✅ Complete user management system  
✅ Real-time monitoring and statistics  
✅ Advanced configuration options  
✅ All Utils components included  

### **Enhanced Features:**
🚀 Modern Python implementation  
🚀 Improved error handling  
🚀 Better logging and monitoring  
🚀 Enhanced security features  
🚀 Updated protocol support  

## 📊 System Requirements

- **OS**: Ubuntu 18.04+ / Debian 9+ (recommended Ubuntu 20.04/22.04)
- **RAM**: Minimum 512MB (1GB+ recommended)
- **Storage**: 2GB+ available space
- **Network**: Public IP address
- **Access**: Root privileges required

## 🔒 Security Features

- **Token-based authentication** with HWID verification
- **Connection limiting** per user
- **Real-time monitoring** of all connections
- **Encrypted communication** channels
- **SSL/TLS certificate** management
- **User isolation** and permissions

## 🛠️ Advanced Configuration

### V2Ray Protocol Selection
When installing V2Ray, you'll see all 27 protocols:
1. TCP
2. Fake HTTP  
3. WebSocket (recommended for most use cases)
4-9. mKCP variants (srtp, utp, wechat-video, dtls, wireguard)
10-27. Advanced protocols (HTTP/2, VLESS, Trojan, etc.)

### SOCKS Custom Headers
Configure custom HTTP response codes for advanced proxy setups:
- **101**: Switching Protocols (standard WebSocket)
- **200**: OK (appears as normal HTTP)
- **300**: Multiple Choices (redirect simulation)
- **301**: Moved Permanently (redirect simulation)

## 📈 Monitoring and Management

### Real-time Statistics
- Active connections per protocol
- User connection counts
- Bandwidth usage monitoring
- Service status indicators
- System resource usage

### User Management
- Create/remove users with expiration dates
- Set connection limits per user
- Monitor user activity in real-time
- Automatic cleanup of expired accounts
- User database backup/restore

## 🔧 Troubleshooting

### Common Issues
1. **"Module system not found"** - Fixed in this version
2. **Permission errors** - Ensure running as root
3. **Network connectivity** - Check firewall settings
4. **Service startup** - Check systemd status

### Log Locations
- **Main logs**: `/var/log/monstervps/`
- **V2Ray logs**: `/var/log/v2ray/`
- **SOCKS logs**: `/var/log/monstervps-socks/`
- **System logs**: `journalctl -u monstervps-*`

## 📞 Support

This is a complete implementation of the original ADMRufu system with all features included. The system has been thoroughly tested and includes all components from the original project.

### Repository Information
- **Original ADMRufu**: https://github.com/rudi9999/ADMRufu
- **MonsterVps Clone**: https://github.com/Mafiadan6/MonsterVps
- **Developer**: mastermind

## 🎯 Version Information

**Current Version**: Complete ADMRufu Clone v1.0  
**Release Date**: July 2025  
**Compatibility**: Full ADMRufu feature parity  
**Status**: Production Ready  

---

**MonsterVps by mastermind** - Complete VPN Management Solution