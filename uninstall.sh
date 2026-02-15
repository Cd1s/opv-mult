#!/bin/bash
#
# OpenVPN Manager - 卸载脚本
# 使用方法: sudo bash uninstall.sh
#

set -e

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================"
echo "OpenVPN Manager 卸载程序"
echo -e "========================================${NC}"
echo ""

# 检查 root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ 请使用 sudo 运行${NC}"
    exit 1
fi

# 确认卸载
echo -e "${YELLOW}⚠️  警告：这将完全卸载 OpenVPN Manager${NC}"
echo ""
echo "将删除："
echo "  - 程序文件: /usr/local/bin/openvpn-manager"
echo "  - 配置目录: /etc/openvpn-manager"
echo "  - 日志文件: /var/log/openvpn-manager.log"
echo "  - Systemd 服务: /etc/systemd/system/openvpn-manager.service"
echo ""
echo -e "${RED}OpenVPN 配置文件和认证信息将被保留在 /etc/openvpn/${NC}"
echo ""

while true; do
    echo -e "${YELLOW}确认卸载？(y/n)${NC}"
    read -r confirm < /dev/tty
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        break
    elif [[ "$confirm" =~ ^[Nn]$ ]]; then
        echo "取消卸载"
        exit 0
    else
        echo -e "${RED}请输入 y 或 n${NC}"
    fi
done

echo ""
echo "🗑️  开始卸载..."

# 停止所有运行中的实例
if command -v openvpn-manager &> /dev/null; then
    echo "停止运行中的实例..."
    openvpn-manager stop 2>/dev/null || true
fi

# 停止并禁用 systemd 服务
if [ -f /etc/systemd/system/openvpn-manager.service ]; then
    echo "停止 systemd 服务..."
    systemctl stop openvpn-manager 2>/dev/null || true
    systemctl disable openvpn-manager 2>/dev/null || true
    rm -f /etc/systemd/system/openvpn-manager.service
    systemctl daemon-reload
    echo -e "${GREEN}✓${NC} Systemd 服务已删除"
fi

# 删除程序文件
if [ -f /usr/local/bin/openvpn-manager ]; then
    rm -f /usr/local/bin/openvpn-manager
    echo -e "${GREEN}✓${NC} 程序文件已删除"
fi

# 删除配置目录
if [ -d /etc/openvpn-manager ]; then
    rm -rf /etc/openvpn-manager
    echo -e "${GREEN}✓${NC} 配置目录已删除"
fi

# 删除日志文件
if [ -f /var/log/openvpn-manager.log ]; then
    rm -f /var/log/openvpn-manager.log
fi
rm -f /var/log/openvpn-*.log
echo -e "${GREEN}✓${NC} 日志文件已删除"

# 清理临时文件
rm -f /tmp/openvpn-*.ovpn 2>/dev/null || true
rm -f /var/run/openvpn-*.pid 2>/dev/null || true

# 清理 OpenVPN 进程
pkill -f "openvpn.*--config" 2>/dev/null || true

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✅ 卸载完成！${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}保留的文件：${NC}"
echo "  - OpenVPN 配置: /etc/openvpn/configs/"
echo "  - 认证信息: /etc/openvpn/auth/"
echo ""
echo "如需完全删除 OpenVPN 相关文件："
echo "  sudo rm -rf /etc/openvpn"
echo ""
