# 安装说明

## 🎯 推荐方式：下载后运行

由于 `curl | bash` 管道方式无法进行交互式输入，**强烈推荐**先下载脚本再运行：

```bash
# 下载安装脚本
wget https://raw.githubusercontent.com/Cd1s/opv-mult/main/install-binary.sh

# 运行（支持完整的交互式配置）
sudo bash install-binary.sh
```

这样你就可以：
- ✅ 输入 OpenVPN 配置文件路径
- ✅ 输入用户名和密码
- ✅ 自定义连接名称和 TUN 设备
- ✅ 选择是否立即启动

---

## 📋 如果使用 `curl | bash` 方式

```bash
curl -sSL https://raw.githubusercontent.com/Cd1s/opv-mult/main/install-binary.sh | sudo bash
```

这种方式会自动跳过交互配置，安装后需要手动配置：

### 手动配置步骤

1. **复制 OpenVPN 配置文件**
```bash
sudo cp your-config.ovpn /etc/openvpn/configs/
```

2. **创建认证文件（如需要）**
```bash
echo "你的用户名" | sudo tee /etc/openvpn/auth/credentials.txt
echo "你的密码" | sudo tee -a /etc/openvpn/auth/credentials.txt
sudo chmod 600 /etc/openvpn/auth/credentials.txt
```

3. **编辑配置文件**
```bash
sudo nano /etc/openvpn-manager/config.yaml
```

内容示例：
```yaml
log_level: info
log_file: /var/log/openvpn-manager.log

instances:
  - name: us-server
    config: /etc/openvpn/configs/your-config.ovpn
    auth_file: /etc/openvpn/auth/credentials.txt  # 如不需要认证就删除这行
    tun_device: tun10
    enabled: true
```

4. **启动连接**
```bash
sudo openvpn-manager start
sudo openvpn-manager status
```

---

## 🆚 两种方式对比

| 方式 | 交互配置 | 便利性 | 推荐度 |
|------|---------|--------|--------|
| **下载后运行** | ✅ 支持 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **curl \| bash** | ❌ 不支持 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |

建议使用**下载后运行**的方式！
