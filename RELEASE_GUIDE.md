# 如何创建 GitHub Release 并上传二进制文件

## 📦 准备好的文件

在 `releases/` 目录下已经编译好了两个二进制文件：

1. **openvpn-manager-linux-amd64** - 适用于 x86_64 架构（大多数服务器）
2. **openvpn-manager-linux-arm64** - 适用于 ARM64 架构（树莓派等）

## 🚀 创建 Release 步骤

### 方法一：通过 GitHub 网页（推荐）

1. **访问 Releases 页面**
   ```
   https://github.com/Cd1s/opv-mult/releases
   ```

2. **点击 "Create a new release"**

3. **填写 Release 信息**
   - **Tag version**: `v1.0.0`
   - **Release title**: `v1.0.0 - 初始发布`
   - **Description**: 
     ```markdown
     ## OpenVPN Multi-Instance Manager v1.0.0
     
     ### 功能特性
     - ✅ 同时管理多个 OpenVPN 连接
     - ✅ 为每个连接创建独立 TUN 设备
     - ✅ 完美集成 Sing-box
     - ✅ 交互式配置向导
     - ✅ 自动健康检查和重启
     
     ### 安装方法
     
     **一键安装：**
     ```bash
     curl -sSL https://raw.githubusercontent.com/Cd1s/opv-mult/main/install-binary.sh | sudo bash
     ```
     
     ### 支持的架构
     - Linux AMD64 (x86_64)
     - Linux ARM64 (aarch64)
     ```

4. **上传二进制文件**
   - 拖拽或点击上传以下文件：
     - `releases/openvpn-manager-linux-amd64`
     - `releases/openvpn-manager-linux-arm64`

5. **点击 "Publish release"**

---

### 方法二：使用命令行（需要 GitHub CLI）

```bash
# 安装 GitHub CLI (如果还没有)
# Debian/Ubuntu
sudo apt-get install gh

# 或从官网下载
# https://cli.github.com/

# 登录
gh auth login

# 创建 release 并上传文件
cd /home/cheek/文件/openvpn转wireguard

gh release create v1.0.0 \
  releases/openvpn-manager-linux-amd64 \
  releases/openvpn-manager-linux-arm64 \
  --title "v1.0.0 - 初始发布" \
  --notes "OpenVPN Multi-Instance Manager 首次发布

## 功能特性
- ✅ 同时管理多个 OpenVPN 连接
- ✅ 为每个连接创建独立 TUN 设备
- ✅ 完美集成 Sing-box
- ✅ 交互式配置向导

## 一键安装
\`\`\`bash
curl -sSL https://raw.githubusercontent.com/Cd1s/opv-mult/main/install-binary.sh | sudo bash
\`\`\`"
```

---

## ✅ 完成后

Release 创建后，二进制安装脚本就可以正常工作了：

```bash
curl -sSL https://raw.githubusercontent.com/Cd1s/opv-mult/main/install-binary.sh | sudo bash
```

这个脚本会：
1. 检测系统架构（AMD64 或 ARM64）
2. 从 GitHub Releases 下载对应的二进制文件
3. 安装到 `/usr/local/bin/openvpn-manager`
4. 交互式配置向导
5. 可选即时启动

---

## 📋 检查 Release

创建成功后，可以访问：
```
https://github.com/Cd1s/opv-mult/releases/latest
```

二进制文件 URL 将是：
```
https://github.com/Cd1s/opv-mult/releases/latest/download/openvpn-manager-linux-amd64
https://github.com/Cd1s/opv-mult/releases/latest/download/openvpn-manager-linux-arm64
```

---

## 🔄 更新 README

创建 Release 后，记得提交以下更改：

```bash
git add install-binary.sh releases/
git commit -m "添加: 预编译二进制文件和安装脚本"
git push
```
