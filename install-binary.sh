#!/bin/bash
#
# OpenVPN Manager - 二进制一键安装
# 使用方法: curl -sSL https://raw.githubusercontent.com/Cd1s/opv-mult/main/install-binary.sh | sudo bash
#

set -e

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================"
echo "OpenVPN Manager 一键安装"
echo -e "========================================${NC}"
echo ""

# 检查 root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ 请使用 sudo 运行${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} Root 权限检查通过"

# 安装 OpenVPN
echo ""
echo "📦 检查依赖..."
if ! command -v openvpn &> /dev/null; then
    echo "正在安装 OpenVPN..."
    if command -v apt-get &> /dev/null; then
        apt-get update -qq && apt-get install -y openvpn >/dev/null 2>&1
    elif command -v yum &> /dev/null; then
        yum install -y openvpn >/dev/null 2>&1
    else
        echo -e "${RED}❌ 无法自动安装 OpenVPN${NC}"
        exit 1
    fi
fi
echo -e "${GREEN}✓${NC} OpenVPN 已就绪"

# 检测架构
ARCH=$(uname -m)
case $ARCH in
    x86_64)
        BINARY="openvpn-manager-linux-amd64"
        ;;
    aarch64|arm64)
        BINARY="openvpn-manager-linux-arm64"
        ;;
    *)
        echo -e "${RED}❌ 不支持的架构: $ARCH${NC}"
        exit 1
        ;;
esac

# 下载二进制
echo ""
echo "📥 下载程序 ($ARCH)..."
DOWNLOAD_URL="https://github.com/Cd1s/opv-mult/releases/download/openvpn-manager/$BINARY"

if command -v wget &> /dev/null; then
    wget -q --show-progress "$DOWNLOAD_URL" -O /usr/local/bin/openvpn-manager 2>&1 || {
        echo -e "${RED}❌ 下载失败，URL: $DOWNLOAD_URL${NC}"
        exit 1
    }
elif command -v curl &> /dev/null; then
    curl -L --progress-bar "$DOWNLOAD_URL" -o /usr/local/bin/openvpn-manager || {
        echo -e "${RED}❌ 下载失败，URL: $DOWNLOAD_URL${NC}"
        exit 1
    }
else
    echo -e "${RED}❌ 需要 wget 或 curl${NC}"
    exit 1
fi

chmod +x /usr/local/bin/openvpn-manager
echo -e "${GREEN}✓${NC} 程序已安装"

# 创建目录
mkdir -p /etc/openvpn-manager /etc/openvpn/configs /etc/openvpn/auth /var/log/openvpn-manager

# 下载配置示例
echo ""
echo "📄 准备配置..."
curl -sSL https://raw.githubusercontent.com/Cd1s/opv-mult/main/config/example.yaml -o /etc/openvpn-manager/config.yaml 2>/dev/null || {
    # 如果下载失败，创建默认配置
    cat > /etc/openvpn-manager/config.yaml <<EOF
log_level: info
log_file: /var/log/openvpn-manager.log

instances:
  - name: vpn-server
    config: /etc/openvpn/configs/config.ovpn
    auth_file: /etc/openvpn/auth/credentials.txt
    tun_device: tun10
    enabled: true
EOF
}

echo -e "${GREEN}✓${NC} 安装完成"

# 交互式配置
echo ""
echo -e "${YELLOW}是否立即配置 OpenVPN 连接？(y/n)${NC}"
read -r configure

if [[ "$configure" =~ ^[Yy]$ ]]; then
    echo ""
    echo "请输入 OpenVPN 配置文件路径 (.ovpn): "
    read -r ovpn_path
    
    if [ -f "$ovpn_path" ]; then
        cp "$ovpn_path" /etc/openvpn/configs/
        ovpn_name=$(basename "$ovpn_path")
        echo -e "${GREEN}✓${NC} 配置文件已复制"
        
        echo ""
        echo -n "是否需要用户名密码认证？(y/n): "
        read -r need_auth
        
        auth_file=""
        if [[ "$need_auth" =~ ^[Yy]$ ]]; then
            echo -n "用户名: "
            read -r username
            echo -n "密码: "
            read -rs password
            echo ""
            
            echo "$username" > /etc/openvpn/auth/credentials.txt
            echo "$password" >> /etc/openvpn/auth/credentials.txt
            chmod 600 /etc/openvpn/auth/credentials.txt
            auth_file="/etc/openvpn/auth/credentials.txt"
            echo -e "${GREEN}✓${NC} 认证信息已保存"
        fi
        
        echo ""
        echo -n "连接名称 (例如 us-server): "
        read -r name
        echo -n "TUN 设备名称 (例如 tun10): "
        read -r tun
        
        # 写入配置
        cat > /etc/openvpn-manager/config.yaml <<EOF
log_level: info
log_file: /var/log/openvpn-manager.log

instances:
  - name: ${name:-vpn-server}
    config: /etc/openvpn/configs/${ovpn_name}
EOF
        
        if [ -n "$auth_file" ]; then
            echo "    auth_file: $auth_file" >> /etc/openvpn-manager/config.yaml
        fi
        
        cat >> /etc/openvpn-manager/config.yaml <<EOF
    tun_device: ${tun:-tun10}
    enabled: true
EOF
        
        echo -e "${GREEN}✓${NC} 配置已保存"
        
        # 立即启动
        echo ""
        echo -e "${YELLOW}立即启动连接？(y/n)${NC}"
        read -r start
        
        if [[ "$start" =~ ^[Yy]$ ]]; then
            echo ""
            echo "🚀 正在启动..."
            openvpn-manager start
            sleep 2
            echo ""
            openvpn-manager status
        fi
    else
        echo -e "${YELLOW}⚠${NC} 配置文件不存在"
        echo "请稍后手动配置: /etc/openvpn-manager/config.yaml"
    fi
fi

echo ""
echo -e "${BLUE}========================================"
echo "✅ 安装成功！"
echo -e "========================================${NC}"
echo ""
echo "常用命令:"
echo "  openvpn-manager start   - 启动所有连接"
echo "  openvpn-manager stop    - 停止所有连接"
echo "  openvpn-manager status  - 查看状态"
echo "  openvpn-manager list    - 列出 TUN 设备"
echo ""
echo "配置文件: /etc/openvpn-manager/config.yaml"
echo ""
