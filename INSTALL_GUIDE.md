# 为什么需要两种安装方式？

## ❓ 问题说明

你遇到的错误是因为缺少 `go.sum` 文件，这个文件记录了所有 Go 依赖的版本信息。

```
missing go.sum entry for module providing package...
```

## ✅ 已修复

我已经生成了 `go.sum` 文件并更新了所有安装脚本，现在有**两种安装方式**：

---

## 🚀 方式一：二进制安装（推荐，无需 Go）⭐

**最简单！适合所有用户！**

```bash
curl -sSL https://raw.githubusercontent.com/Cd1s/opv-mult/main/install-binary.sh | sudo bash
```

### 优点：
- ✅ **不需要安装 Go**
- ✅ 直接下载编译好的程序
- ✅ 速度快（不需要编译）
- ✅ 节省资源

### 工作原理：
1. 下载预编译的二进制文件
2. 安装到系统
3. 交互式配置

---

## 🔨 方式二：源码编译安装

**适合需要自定义或学习代码的用户**

```bash
curl -sSL https://raw.githubusercontent.com/Cd1s/opv-mult/main/quick-install.sh | sudo bash
```

### 优点：
- ✅ 可以查看源代码
- ✅ 可以自定义修改
- ✅ 支持任何架构

### 工作原理：
1. 克隆 GitHub 仓库
2. 自动安装 Go 和 OpenVPN
3. 运行 `go mod tidy` 下载依赖
4. 编译并安装
5. 交互式配置

---

## 📝 已修复的文件

1. **go.sum** - 新增，解决依赖问题
2. **install.sh** - 添加了 `go mod tidy` 步骤
3. **quick-install.sh** - 添加了 `go mod tidy` 步骤  
4. **install-binary.sh** - 新增，二进制安装脚本

---

## 🎯 推荐使用方式

### 普通用户（推荐）
```bash
# 二进制安装 - 最简单
curl -sSL https://raw.githubusercontent.com/Cd1s/opv-mult/main/install-binary.sh | sudo bash
```

### 开发者/高级用户
```bash
# 源码安装 - 可自定义
git clone https://github.com/Cd1s/opv-mult.git
cd opv-mult
sudo bash install.sh
```

---

## 🔧 技术细节

### go.sum 文件的作用

`go.sum` 文件记录了：
- 每个依赖包的精确版本
- 每个包的哈希值（确保安全）

没有这个文件时，Go 会拒绝下载依赖（安全机制）。

### 解决方案

运行 `go mod tidy` 会：
1. 分析代码的依赖
2. 下载所需的包
3. 生成 `go.sum` 文件
4. 确保依赖版本一致

现在所有安装脚本都会自动执行这一步！
