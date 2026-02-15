#!/bin/bash
#
# OpenVPN Multi-Instance Manager - 一键安装脚本
# 

set -e

echo "========================================"
echo "OpenVPN Manager 安装程序"
echo "========================================"
echo ""

# 检查是否为 root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ 错误: 请使用 root 权限运行此脚本"
    echo "   使用: sudo ./install.sh"
    exit 1
fi

echo "✓ Root 权限检查通过"

# 检查 OpenVPN 是否安装
if ! command -v openvpn &> /dev/null; then
    echo ""
    echo "📦 OpenVPN 未安装，正在安装..."
    if command -v apt-get &> /dev/null; then
        apt-get update
        apt-get install -y openvpn
    elif command -v yum &> /dev/null; then
        yum install -y openvpn
    else
        echo "❌ 无法自动安装 OpenVPN，请手动安装后重试"
        exit 1
    fi
    echo "✓ OpenVPN 安装完成"
else
    echo "✓ OpenVPN 已安装"
fi

# 检查 Go 是否安装
if ! command -v go &> /dev/null; then
    echo ""
    echo "❌ Go 未安装，请先安装 Go 1.20 或更高版本"
    echo "   下载地址: https://go.dev/dl/"
    echo ""
    echo "   Debian/Ubuntu 快速安装:"
    echo "   sudo apt-get update"
    echo "   sudo apt-get install -y golang-go"
    exit 1
fi

echo "✓ Go 已安装 ($(go version))"

# 编译程序
echo ""
echo "📦 正在编译程序..."
go mod download
go build -o openvpn-manager main.go

if [ ! -f openvpn-manager ]; then
    echo "❌ 编译失败"
    exit 1
fi

echo "✓ 编译完成"

# 安装二进制文件
echo ""
echo "📦 正在安装到系统..."
cp openvpn-manager /usr/local/bin/
chmod +x /usr/local/bin/openvpn-manager
echo "✓ 二进制文件已安装到 /usr/local/bin/openvpn-manager"

# 创建配置目录
mkdir -p /etc/openvpn-manager
mkdir -p /etc/openvpn/configs
mkdir -p /etc/openvpn/auth
mkdir -p /var/log/openvpn-manager
echo "✓ 配置目录已创建"

# 复制示例配置（如果不存在）
if [ ! -f /etc/openvpn-manager/config.yaml ]; then
    cp config/example.yaml /etc/openvpn-manager/config.yaml
    echo "✓ 示例配置文件已复制到 /etc/openvpn-manager/config.yaml"
else
    echo "⚠ 配置文件已存在，跳过复制"
fi

# 安装 systemd 服务（可选）
if [ -f openvpn-manager.service ]; then
    cp openvpn-manager.service /etc/systemd/system/
    systemctl daemon-reload
    echo "✓ Systemd 服务已安装"
fi

echo ""
echo "========================================"
echo "✅ 安装完成！"
echo "========================================"
echo ""
echo "下一步操作："
echo ""
echo "1. 将你的 ExpressVPN 配置文件放到:"
echo "   /etc/openvpn/configs/"
echo ""
echo "2. 如果需要认证，创建认证文件:"
echo "   echo 'your_username' > /etc/openvpn/auth/server.txt"
echo "   echo 'your_password' >> /etc/openvpn/auth/server.txt"
echo ""
echo "3. 编辑配置文件:"
echo "   nano /etc/openvpn-manager/config.yaml"
echo ""
echo "4. 启动 OpenVPN 连接:"
echo "   openvpn-manager start"
echo ""
echo "5. 查看状态:"
echo "   openvpn-manager status"
echo ""
echo "6. 查看 TUN 设备列表（用于 Sing-box）:"
echo "   openvpn-manager list"
echo ""
echo "可选: 启用开机自启动"
echo "   systemctl enable openvpn-manager"
echo "   systemctl start openvpn-manager"
echo ""
