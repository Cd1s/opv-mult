# OpenVPN 认证问题修复指南

## 问题描述

你遇到的错误：
```
Password entry required for 'Enter Auth Username:' (PID 1821880).
Please enter password with the systemd-tty-ask-password-agent tool.
```

## 原因

你的 `.ovpn` 文件中有这一行：
```
auth-user-pass
```

这会导致 OpenVPN 尝试交互式请求用户名密码，但因为是 daemon 模式运行，无法交互输入。

## 解决方案

### 方法一：修改 .ovpn 文件（推荐）

编辑你的 `.ovpn` 文件，找到这一行：
```
auth-user-pass
```

修改为：
```
auth-user-pass /etc/openvpn/auth/credentials.txt
```

然后创建认证文件：
```bash
echo "你的用户名" | sudo tee /etc/openvpn/auth/credentials.txt
echo "你的密码" | sudo tee -a /etc/openvpn/auth/credentials.txt
sudo chmod 600 /etc/openvpn/auth/credentials.txt
```

### 方法二：使用配置文件指定（也可以）

保持 `.ovpn` 文件中的 `auth-user-pass` **删除掉或注释掉**，然后在 `/etc/openvpn-manager/config.yaml` 中指定：

```yaml
log_level: info
log_file: /var/log/openvpn-manager.log

instances:
  - name: mo-server
    config: /etc/openvpn/configs/your-config.ovpn
    auth_file: /etc/openvpn/auth/credentials.txt  # 这里指定认证文件
    tun_device: tun-mo
    enabled: true
```

创建认证文件：
```bash
echo "你的用户名" | sudo tee /etc/openvpn/auth/credentials.txt
echo "你的密码" | sudo tee -a /etc/openvpn/auth/credentials.txt
sudo chmod 600 /etc/openvpn/auth/credentials.txt
```

### 方法三：完全移除认证（如果不需要）

如果你的 VPN 不需要用户名密码认证，直接从 `.ovpn` 文件中删除这一行：
```
auth-user-pass
```

## 验证

修改后重新启动：
```bash
sudo openvpn-manager stop
sudo openvpn-manager start
sudo openvpn-manager status
```

应该看到：
```
Instance: mo-server
  Status:     running
  TUN Device: tun-mo
  IP:         10.x.x.x
```

## 快速修复脚本

```bash
#!/bin/bash

# 1. 创建认证文件
echo "输入你的 ExpressVPN 用户名:"
read username
echo "输入你的密码:"
read -s password

sudo mkdir -p /etc/openvpn/auth
echo "$username" | sudo tee /etc/openvpn/auth/credentials.txt
echo "$password" | sudo tee -a /etc/openvpn/auth/credentials.txt
sudo chmod 600 /etc/openvpn/auth/credentials.txt

echo "✓ 认证文件已创建"

# 2. 修改 .ovpn 文件（替换 your-config.ovpn）
sudo sed -i 's/^auth-user-pass$/auth-user-pass \/etc\/openvpn\/auth\/credentials.txt/' /etc/openvpn/configs/your-config.ovpn

echo "✓ 配置文件已更新"

# 3. 重启服务
sudo openvpn-manager stop
sudo openvpn-manager start

echo "✓ 服务已重启"

# 4. 查看状态
sleep 3
sudo openvpn-manager status
```

保存为 `fix-auth.sh`，然后运行：
```bash
chmod +x fix-auth.sh
sudo ./fix-auth.sh
```
