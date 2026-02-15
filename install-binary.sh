#!/bin/bash
#
# 二进制安装脚本 - 无需 Go 环境
# 使用方法: curl -sSL https://raw.githubusercontent.com/Cd1s/opv-mult/main/install-binary.sh | sudo bash
#

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================"
echo "OpenVPN Manager 二进制安装"
echo -e "========================================${NC}"
echo ""

# 检查是否为 root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ 请使用 root 权限运行${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} Root 权限检查通过"

# 自动安装 OpenVPN
echo ""
echo "📦 检查依赖..."
if ! command -v openvpn &> /dev/null; then
    echo "正在安装 OpenVPN..."
    if command -v apt-get &> /dev/null; then
        apt-get update -qq && apt-get install -y openvpn >/dev/null 2>&1
    elif command -v yum &> /dev/null; then
        yum install -y openvpn >/dev/null 2>&1
    fi
fi
echo -e "${GREEN}✓${NC} OpenVPN 已就绪"

# 检测系统架构
ARCH=$(uname -m)
case $ARCH in
    x86_64)
        BINARY_URL="https://github.com/Cd1s/opv-mult/releases/latest/download/openvpn-manager-linux-amd64"
        ;;
    aarch64|arm64)
        BINARY_URL="https://github.com/Cd1s/opv-mult/releases/latest/download/openvpn-manager-linux-arm64"
        ;;
    *)
        echo -e "${RED}❌ 不支持的架构: $ARCH${NC}"
        echo "请使用源码安装: https://github.com/Cd1s/opv-mult"
        exit 1
        ;;
esac

# 下载二进制文件
echo ""
echo "📥 下载程序..."
if command -v wget &> /dev/null; then
    wget -q "$BINARY_URL" -O /usr/local/bin/openvpn-manager
elif command -v curl &> /dev/null; then
    curl -sSL "$BINARY_URL" -o /usr/local/bin/openvpn-manager
else
    echo -e "${RED}❌ 需要 wget 或 curl${NC}"
    exit 1
fi

chmod +x /usr/local/bin/openvpn-manager
echo -e "${GREEN}✓${NC} 程序已安装"

# 创建目录
mkdir -p /etc/openvpn-manager /etc/openvpn/configs /etc/openvpn/auth /var/log/openvpn-manager

# 下载示例配置
echo ""
echo "📄 下载配置文件..."
curl -sSL https://raw.githubusercontent.com/Cd1s/opv-mult/main/config/example.yaml -o /etc/openvpn-manager/config.yaml

echo -e "${GREEN}✓${NC} 安装完成！"

# 交互式配置
echo ""
echo -e "${YELLOW}是否立即配置？(y/n)${NC}"
read -r configure

if [[ "$configure" =~ ^[Yy]$ ]]; then
    echo ""
    echo "请输入 OpenVPN 配置文件路径 (.ovpn): "
    read -r ovpn_path
    
    if [ -f "$ovpn_path" ]; then
        cp "$ovpn_path" /etc/openvpn/configs/
        ovpn_name=$(basename "$ovpn_path")
        echo -e "${GREEN}✓${NC} 已复制"
        
        echo -n "用户名 (如不需要按回车): "
        read -r username
        
        auth_file=""
        if [ -n "$username" ]; then
            echo -n "密码: "
            read -rs password
            echo ""
            echo "$username" > /etc/openvpn/auth/credentials.txt
            echo "$password" >> /etc/openvpn/auth/credentials.txt
            chmod 600 /etc/openvpn/auth/credentials.txt
            auth_file="/etc/openvpn/auth/credentials.txt"
        fi
        
        echo -n "连接名称: "
        read -r name
        echo -n "TUN 设备 (如 tun10): "
        read -r tun
        
        cat > /etc/openvpn-manager/config.yaml <<EOF
log_level: info
log_file: /var/log/openvpn-manager.log

instances:
  - name: ${name:-vpn}
    config: /etc/openvpn/configs/${ovpn_name}
EOF
        if [ -n "$auth_file" ]; then
            echo "    auth_file: $auth_file" >> /etc/openvpn-manager/config.yaml
        fi
        cat >> /etc/openvpn-manager/config.yaml <<EOF
    tun_device: ${tun:-tun10}
    enabled: true
EOF
        
        echo -e "${GREEN}✓${NC} 配置完成"
        
        echo ""
        echo -e "${YELLOW}立即启动？(y/n)${NC}"
        read -r start
        if [[ "$start" =~ ^[Yy]$ ]]; then
            openvpn-manager start
            sleep 2
            openvpn-manager status
        fi
    fi
fi

echo ""
echo -e "${BLUE}========================================"
echo "安装成功！"
echo -e "========================================${NC}"
echo ""
echo "使用: openvpn-manager start/stop/status/list"
echo ""
