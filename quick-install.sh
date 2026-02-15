#!/bin/bash
#
# OpenVPN Manager - 超级一键安装脚本
# 从 GitHub 克隆并自动安装
#
# 使用方法: 
# curl -sSL https://raw.githubusercontent.com/Cd1s/opv-mult/main/quick-install.sh | sudo bash
#

set -e

REPO_URL="https://github.com/Cd1s/opv-mult.git"
INSTALL_DIR="/tmp/opv-mult-install"

echo "========================================"
echo "OpenVPN Manager 超级一键安装"
echo "========================================"
echo ""

# 检查 root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ 请使用 sudo 运行"
    exit 1
fi

# 安装 git
if ! command -v git &> /dev/null; then
    echo "📦 安装 git..."
    if command -v apt-get &> /dev/null; then
        apt-get update -qq && apt-get install -y git >/dev/null 2>&1
    elif command -v yum &> /dev/null; then
        yum install -y git >/dev/null 2>&1
    fi
fi

# 克隆仓库
echo "📥 下载源码..."
rm -rf "$INSTALL_DIR"
git clone "$REPO_URL" "$INSTALL_DIR" >/dev/null 2>&1
cd "$INSTALL_DIR"

# 运行安装
echo "🚀 开始安装..."
bash install.sh

# 清理
cd /
rm -rf "$INSTALL_DIR"

echo ""
echo "✅ 全部完成！享受使用吧！"
