# 🚨 紧急恢复指南

## 问题：启动 OpenVPN 后断网了！

### 原因
OpenVPN 默认会接管所有网络流量（`redirect-gateway` 或 `pull` 指令），导致你的服务器断网。

### 🔥 立即恢复网络

#### 方法一：停止 OpenVPN（推荐）
如果你还能连接服务器：
```bash
sudo openvpn-manager stop
```

如果无法连接，从其他终端或控制台：
```bash
sudo pkill openvpn
sudo ip route add default via <你的网关IP>
```

#### 方法二：重启服务器
如果完全无法连接，只能重启服务器恢复网络。

---

## ✅ 永久解决方案

### 修改配置文件，禁止接管路由

编辑你的 `.ovpn` 文件：
```bash
sudo nano /etc/openvpn/configs/your-config.ovpn
```

**在文件末尾添加这一行**：
```
route-nopull
```

这会告诉 OpenVPN：**不要接管我的默认路由，只创建 TUN 设备**。

### 保存后重启
```bash
sudo openvpn-manager stop
sudo openvpn-manager start
sudo openvpn-manager status
```

---

## 🔐 配置认证文件

### 1. 创建认证文件
```bash
# 创建认证文件
sudo nano /etc/openvpn/auth/credentials.txt
```

内容（两行）：
```
你的ExpressVPN用户名
你的ExpressVPN密码
```

### 2. 设置权限
```bash
sudo chmod 600 /etc/openvpn/auth/credentials.txt
```

### 3. 确认配置文件
编辑 `/etc/openvpn-manager/config.yaml`：
```bash
sudo nano /etc/openvpn-manager/config.yaml
```

确保有 `auth_file` 这一行：
```yaml
log_level: info
log_file: /var/log/openvpn-manager.log

instances:
  - name: mo-server
    config: /etc/openvpn/configs/your-config.ovpn
    auth_file: /etc/openvpn/auth/credentials.txt  # 这一行必须有
    tun_device: tun-mo
    enabled: true
```

---

## 🎯 完整步骤（从头开始）

```bash
# 1. 停止服务
sudo openvpn-manager stop

# 2. 修改 .ovpn 文件，添加 route-nopull
sudo bash -c "echo 'route-nopull' >> /etc/openvpn/configs/your-config.ovpn"

# 3. 创建认证文件
echo "你的用户名" | sudo tee /etc/openvpn/auth/credentials.txt
echo "你的密码" | sudo tee -a /etc/openvpn/auth/credentials.txt
sudo chmod 600 /etc/openvpn/auth/credentials.txt

# 4. 确认配置文件有 auth_file
sudo nano /etc/openvpn-manager/config.yaml

# 5. 重新启动
sudo openvpn-manager start
sleep 3
sudo openvpn-manager status

# 6. 测试网络
ping -c 3 8.8.8.8
```

---

## 📋 验证

成功的输出应该是：
```
Instance: mo-server
  Status:     running
  TUN Device: tun-mo
  IP:         10.x.x.x
  Uptime:     XXs
```

并且你的服务器网络正常，可以 ping 通外网。

---

## 🔍 理解 route-nopull 的作用

- **不加 route-nopull**：OpenVPN 会接管所有流量，你的服务器断网
- **加了 route-nopull**：OpenVPN 只创建 TUN 设备，不修改路由表，你可以通过 Sing-box 手动控制哪些流量走 VPN

这正是我们想要的效果！Sing-box 会使用 `bind_interface: tun-mo` 来指定流量走这个 VPN，而不是让 OpenVPN 接管所有流量。

---

## 🆘 如果还是有问题

### 查看日志
```bash
# OpenVPN 日志
sudo tail -50 /var/log/openvpn-tun-mo.log

# 管理器日志
sudo tail -50 /var/log/openvpn-manager.log

# 系统日志
sudo journalctl -u openvpn -n 50
```

### 检查路由表
```bash
# 查看路由表
ip route

# 查看 TUN 设备
ip addr show tun-mo
```

### 手动测试 OpenVPN
```bash
sudo openvpn --config /etc/openvpn/configs/your-config.ovpn \
  --auth-user-pass /etc/openvpn/auth/credentials.txt \
  --dev tun-mo \
  --route-nopull
```

按 Ctrl+C 停止测试。
