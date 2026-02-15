# 更新指南

## 🔄 如何更新到最新版本

如果你已经安装了旧版本，需要更新到支持 ExpressVPN 默认配置的新版本。

### 方法一：重新运行安装脚本（推荐）

```bash
# 下载最新安装脚本
wget https://raw.githubusercontent.com/Cd1s/opv-mult/main/install-binary.sh

# 运行安装（会自动覆盖旧版本）
sudo bash install-binary.sh
```

跳过配置步骤（输入 n），因为你的配置已经存在。

### 方法二：手动下载二进制文件

```bash
# 停止服务
sudo openvpn-manager stop

# 备份旧版本
sudo mv /usr/local/bin/openvpn-manager /usr/local/bin/openvpn-manager.old

# 下载新版本（AMD64）
sudo wget https://github.com/Cd1s/opv-mult/releases/download/openvpn-manager/openvpn-manager-linux-amd64 \
  -O /usr/local/bin/openvpn-manager

# 或 ARM64
# sudo wget https://github.com/Cd1s/opv-mult/releases/download/openvpn-manager/openvpn-manager-linux-arm64 \
#   -O /usr/local/bin/openvpn-manager

# 添加执行权限
sudo chmod +x /usr/local/bin/openvpn-manager

# 重启服务
sudo openvpn-manager start
```

### 方法三：从源码编译

```bash
# 克隆或更新仓库
cd /tmp
git clone https://github.com/Cd1s/opv-mult.git
cd opv-mult

# 或如果已经克隆过
# cd /path/to/opv-mult
# git pull

# 编译
go build -o openvpn-manager main.go

# 停止服务并安装
sudo openvpn-manager stop
sudo cp openvpn-manager /usr/local/bin/
sudo openvpn-manager start
```

## ✅ 验证更新

```bash
# 启动服务
sudo openvpn-manager start

# 等待 3 秒
sleep 3

# 查看状态
sudo openvpn-manager status
```

应该看到：
```
Instance: your-server
  Status:     running
  TUN Device: tun10
  IP:         10.x.x.x
```

## 🔍 检查日志

如果还有问题：
```bash
# 查看管理器日志
sudo tail -f /var/log/openvpn-manager.log

# 查看 OpenVPN 日志
sudo tail -f /var/log/openvpn-tun10.log
```

## 📝 新版本改进

- ✅ 自动处理 `.ovpn` 文件中的 `auth-user-pass` 指令
- ✅ 无需手动修改 ExpressVPN 配置文件
- ✅ 自动创建临时配置文件
- ✅ 停止时自动清理临时文件
