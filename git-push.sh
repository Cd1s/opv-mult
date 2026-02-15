#!/bin/bash
#
# Git 推送助手脚本
# 自动推送到 GitHub
#

set -e

echo "========================================"
echo "Git 推送助手"
echo "========================================"
echo ""

# 检查是否在 git 仓库中
if [ ! -d .git ]; then
    echo "❌ 当前目录不是 Git 仓库"
    exit 1
fi

# 检查是否有未提交的改动
if [ -n "$(git status --porcelain)" ]; then
    echo "📝 发现未提交的改动，正在提交..."
    git add .
    git commit -m "Update: $(date '+%Y-%m-%d %H:%M:%S')"
fi

# 检查远程仓库
if ! git remote | grep -q origin; then
    echo "❌ 未配置远程仓库"
    echo "请先运行: git remote add origin https://github.com/Cd1s/opv-mult.git"
    exit 1
fi

echo "🚀 准备推送到 GitHub..."
echo ""
echo "请选择认证方式："
echo "  1) Personal Access Token (推荐)"
echo "  2) SSH Key"
echo "  3) 取消"
echo ""
read -p "选择 (1-3): " choice

case $choice in
    1)
        echo ""
        echo "📌 使用 Personal Access Token"
        echo ""
        echo "如果你还没有 token，请访问："
        echo "https://github.com/settings/tokens"
        echo ""
        echo "推送中... (需要输入用户名和 token)"
        git push -u origin main
        ;;
    2)
        echo ""
        echo "📌 使用 SSH Key"
        echo ""
        echo "切换到 SSH URL..."
        git remote set-url origin git@github.com:Cd1s/opv-mult.git
        echo "推送中..."
        git push -u origin main
        ;;
    3)
        echo "取消推送"
        exit 0
        ;;
    *)
        echo "❌ 无效选择"
        exit 1
        ;;
esac

echo ""
echo "========================================"
echo "✅ 推送成功！"
echo "========================================"
echo ""
echo "你的项目现在可以在这里查看："
echo "https://github.com/Cd1s/opv-mult"
echo ""
