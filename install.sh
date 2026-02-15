#!/bin/bash
#
# OpenVPN Multi-Instance Manager - 真正的一键安装脚本
# 使用方法: sudo bash install.sh
#

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================"
echo "OpenVPN Manager 一键安装"
echo -e "========================================${NC}"
echo ""

# 检查是否为 root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ 错误: 请使用 root 权限运行此脚本${NC}"
    echo "   使用: sudo bash install.sh"
    exit 1
fi

echo -e "${GREEN}✓${NC} Root 权限检查通过"

# 自动安装依赖
echo ""
echo "📦 检查并安装依赖..."

# 检查并安装 OpenVPN
if ! command -v openvpn &> /dev/null; then
    echo "正在安装 OpenVPN..."
    if command -v apt-get &> /dev/null; then
        apt-get update -qq
        apt-get install -y openvpn >/dev/null 2>&1
    elif command -v yum &> /dev/null; then
        yum install -y openvpn >/dev/null 2>&1
    else
        echo -e "${RED}❌ 无法自动安装 OpenVPN${NC}"
        exit 1
    fi
fi
echo -e "${GREEN}✓${NC} OpenVPN 已就绪"

# 检查并安装 Go
if ! command -v go &> /dev/null; then
    echo "正在安装 Go..."
    if command -v apt-get &> /dev/null; then
        apt-get install -y golang-go >/dev/null 2>&1
    elif command -v yum &> /dev/null; then
        yum install -y golang >/dev/null 2>&1
    else
        echo -e "${RED}❌ 无法自动安装 Go${NC}"
        echo "请手动安装: https://go.dev/dl/"
        exit 1
    fi
fi
echo -e "${GREEN}✓${NC} Go 已就绪 ($(go version | awk '{print $3}'))"

# 编译程序
echo ""
echo "🔨 正在编译程序..."
go mod download >/dev/null 2>&1
go build -o openvpn-manager main.go

if [ ! -f openvpn-manager ]; then
    echo -e "${RED}❌ 编译失败${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} 编译完成"

# 安装程序
echo ""
echo "📦 正在安装..."
install -m 755 openvpn-manager /usr/local/bin/
mkdir -p /etc/openvpn-manager /etc/openvpn/configs /etc/openvpn/auth /var/log/openvpn-manager

# 创建默认配置
if [ ! -f /etc/openvpn-manager/config.yaml ]; then
    cp config/example.yaml /etc/openvpn-manager/config.yaml
    echo -e "${GREEN}✓${NC} 配置文件已创建"
fi

# 安装 systemd 服务
if [ -f openvpn-manager.service ]; then
    cp openvpn-manager.service /etc/systemd/system/
    systemctl daemon-reload
    echo -e "${GREEN}✓${NC} Systemd 服务已安装"
fi

echo -e "${GREEN}✓${NC} 安装完成"

# 询问是否配置
echo ""
echo -e "${YELLOW}是否立即配置 OpenVPN 连接？(y/n)${NC}"
read -r configure

if [[ "$configure" =~ ^[Yy]$ ]]; then
    echo ""
    echo "请输入配置信息："
    
    # 获取配置文件路径
    echo -n "OpenVPN 配置文件路径 (.ovpn): "
    read -r ovpn_path
    
    if [ -f "$ovpn_path" ]; then
        cp "$ovpn_path" /etc/openvpn/configs/
        ovpn_name=$(basename "$ovpn_path")
        echo -e "${GREEN}✓${NC} 配置文件已复制"
    else
        echo -e "${YELLOW}⚠${NC} 配置文件不存在，请稍后手动复制到 /etc/openvpn/configs/"
        ovpn_name="your-config.ovpn"
    fi
    
    # 询问是否需要认证
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
    
    # 生成配置文件
    echo -n "连接名称 (例如 us-server): "
    read -r instance_name
    
    echo -n "TUN 设备名称 (例如 tun10): "
    read -r tun_device
    
    # 写入配置
    cat > /etc/openvpn-manager/config.yaml <<EOF
log_level: info
log_file: /var/log/openvpn-manager.log

instances:
  - name: ${instance_name:-us-server}
    config: /etc/openvpn/configs/${ovpn_name}
EOF
    
    if [ -n "$auth_file" ]; then
        echo "    auth_file: $auth_file" >> /etc/openvpn-manager/config.yaml
    fi
    
    cat >> /etc/openvpn-manager/config.yaml <<EOF
    tun_device: ${tun_device:-tun10}
    enabled: true
EOF
    
    echo -e "${GREEN}✓${NC} 配置已保存到 /etc/openvpn-manager/config.yaml"
    
    # 询问是否立即启动
    echo ""
    echo -e "${YELLOW}是否立即启动 OpenVPN 连接？(y/n)${NC}"
    read -r start_now
    
    if [[ "$start_now" =~ ^[Yy]$ ]]; then
        echo ""
        echo "🚀 正在启动..."
        openvpn-manager start
        sleep 2
        echo ""
        openvpn-manager status
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
echo "配置文件位置:"
echo "  /etc/openvpn-manager/config.yaml"
echo ""
echo "开机自启:"
echo "  systemctl enable openvpn-manager"
echo ""

