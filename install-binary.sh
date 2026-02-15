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

# 交互式配置 - 循环直到得到明确答案
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}📋 现在配置 OpenVPN 连接${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "需要准备："
echo "  1. OpenVPN 配置文件 (.ovpn)"
echo "  2. 用户名和密码（如果需要认证）"
echo ""

while true; do
    echo -e "${YELLOW}是否立即配置？(y/n)${NC}"
    read -r configure < /dev/tty
    
    if [[ "$configure" =~ ^[Yy]$ ]]; then
        break
    elif [[ "$configure" =~ ^[Nn]$ ]]; then
        echo ""
        echo -e "${YELLOW}⚠ 跳过配置${NC}"
        echo "稍后可以手动配置："
        echo "  1. 复制 .ovpn 文件到 /etc/openvpn/configs/"
        echo "  2. 编辑 /etc/openvpn-manager/config.yaml"
        echo "  3. 运行: openvpn-manager start"
        echo ""
        echo -e "${BLUE}========================================${NC}"
        echo "✅ 安装成功！"
        echo -e "${BLUE}========================================${NC}"
        echo ""
        echo "常用命令:"
        echo "  openvpn-manager start   - 启动所有连接"
        echo "  openvpn-manager stop    - 停止所有连接"
        echo "  openvpn-manager status  - 查看状态"
        echo "  openvpn-manager list    - 列出 TUN 设备"
        echo ""
        echo "配置文件: /etc/openvpn-manager/config.yaml"
        echo ""
        exit 0
    else
        echo -e "${RED}请输入 y 或 n${NC}"
    fi
done

# 进入配置流程
echo ""
echo -e "${GREEN}━━━ 开始配置 ━━━${NC}"
echo ""

# 获取 OpenVPN 配置文件
while true; do
    echo -e "${YELLOW}请输入 OpenVPN 配置文件路径 (.ovpn):${NC}"
    read -r ovpn_path < /dev/tty
    
    if [ -f "$ovpn_path" ]; then
        cp "$ovpn_path" /etc/openvpn/configs/
        ovpn_name=$(basename "$ovpn_path")
        echo -e "${GREEN}✓${NC} 配置文件已复制: $ovpn_name"
        break
    else
        echo -e "${RED}❌ 文件不存在: $ovpn_path${NC}"
        echo "请重新输入或按 Ctrl+C 退出"
    fi
done

# 询问认证
echo ""
while true; do
    echo -e "${YELLOW}是否需要用户名密码认证？(y/n)${NC}"
    read -r need_auth < /dev/tty
    
    if [[ "$need_auth" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}用户名:${NC}"
        read -r username < /dev/tty
        echo -e "${YELLOW}密码:${NC}"
        read -rs password < /dev/tty
        echo ""
        
        echo "$username" > /etc/openvpn/auth/credentials.txt
        echo "$password" >> /etc/openvpn/auth/credentials.txt
        chmod 600 /etc/openvpn/auth/credentials.txt
        auth_file="/etc/openvpn/auth/credentials.txt"
        echo -e "${GREEN}✓${NC} 认证信息已保存"
        break
    elif [[ "$need_auth" =~ ^[Nn]$ ]]; then
        auth_file=""
        echo -e "${GREEN}✓${NC} 无需认证"
        break
    else
        echo -e "${RED}请输入 y 或 n${NC}"
    fi
done

# 连接名称
echo ""
echo -e "${YELLOW}连接名称 (例如 us-server):${NC}"
read -r name < /dev/tty
name=${name:-vpn-server}

# TUN 设备
echo -e "${YELLOW}TUN 设备名称 (例如 tun10，直接回车使用默认 tun10):${NC}"
read -r tun < /dev/tty
tun=${tun:-tun10}

# 写入配置
cat > /etc/openvpn-manager/config.yaml <<EOF
log_level: info
log_file: /var/log/openvpn-manager.log

instances:
  - name: $name
    config: /etc/openvpn/configs/$ovpn_name
EOF

if [ -n "$auth_file" ]; then
    echo "    auth_file: $auth_file" >> /etc/openvpn-manager/config.yaml
fi

cat >> /etc/openvpn-manager/config.yaml <<EOF
    tun_device: $tun
    enabled: true
EOF

echo ""
echo -e "${GREEN}✓${NC} 配置已保存到 /etc/openvpn-manager/config.yaml"

# 立即启动
echo ""
while true; do
    echo -e "${YELLOW}立即启动连接？(y/n)${NC}"
    read -r start < /dev/tty
    
    if [[ "$start" =~ ^[Yy]$ ]]; then
        echo ""
        echo "🚀 正在启动..."
        openvpn-manager start
        sleep 3
        echo ""
        openvpn-manager status
        break
    elif [[ "$start" =~ ^[Nn]$ ]]; then
        echo ""
        echo -e "${GREEN}✓${NC} 稍后可以使用以下命令启动:"
        echo "  sudo openvpn-manager start"
        break
    else
        echo -e "${RED}请输入 y 或 n${NC}"
    fi
done

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
