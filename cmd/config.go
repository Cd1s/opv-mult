package cmd

import (
	"bufio"
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"

	"github.com/spf13/cobra"
	"gopkg.in/yaml.v3"

	"github.com/Cd1s/opv-mult/config"
)

var configCmd = &cobra.Command{
	Use:   "config",
	Short: "Interactive configuration manager",
	Long:  "Add, edit, or remove OpenVPN configurations interactively",
	Run: func(cmd *cobra.Command, args []string) {
		runInteractiveConfig()
	},
}

func init() {
	rootCmd.AddCommand(configCmd)
}

func runInteractiveConfig() {
	reader := bufio.NewReader(os.Stdin)
	
	for {
		fmt.Println("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
		fmt.Println("📋 OpenVPN Manager - 配置管理")
		fmt.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
		fmt.Println()
		fmt.Println("1. 查看当前配置")
		fmt.Println("2. 添加新配置")
		fmt.Println("3. 删除配置")
		fmt.Println("4. 启用/禁用配置")
		fmt.Println("5. 退出")
		fmt.Println()
		fmt.Print("请选择 (1-5): ")
		
		choice, _ := reader.ReadString('\n')
		choice = strings.TrimSpace(choice)
		
		switch choice {
		case "1":
			showConfigs()
		case "2":
			addConfig(reader)
		case "3":
			removeConfig(reader)
		case "4":
			toggleConfig(reader)
		case "5":
			fmt.Println("\n👋 再见！")
			return
		default:
			fmt.Println("\n❌ 无效选择")
		}
	}
}

func showConfigs() {
	cfg, err := config.LoadConfig(configFile)
	if err != nil {
		fmt.Printf("\n❌ 无法加载配置: %v\n", err)
		return
	}
	
	fmt.Println("\n━━━ 当前配置 ━━━")
	if len(cfg.Instances) == 0 {
		fmt.Println("(无配置)")
		return
	}
	
	for idx, inst := range cfg.Instances {
		status := "✓ 启用"
		if !inst.Enabled {
			status = "✗ 禁用"
		}
		fmt.Printf("\n%d. %s [%s]\n", idx+1, inst.Name, status)
		fmt.Printf("   配置文件: %s\n", inst.ConfigPath)
		fmt.Printf("   TUN设备:  %s\n", inst.TunDevice)
		if inst.AuthFile != "" {
			fmt.Printf("   认证文件: %s\n", inst.AuthFile)
		}
	}
}

func addConfig(reader *bufio.Reader) {
	fmt.Println("\n━━━ 添加新配置 ━━━")
	
	// 配置名称
	fmt.Print("\n连接名称 (例如 us-server): ")
	name, _ := reader.ReadString('\n')
	name = strings.TrimSpace(name)
	if name == "" {
		fmt.Println("❌ 名称不能为空")
		return
	}
	
	// .ovpn 文件路径
	fmt.Print(".ovpn 配置文件路径: ")
	ovpnPath, _ := reader.ReadString('\n')
	ovpnPath = strings.TrimSpace(ovpnPath)
	
	if _, err := os.Stat(ovpnPath); os.IsNotExist(err) {
		fmt.Printf("❌ 文件不存在: %s\n", ovpnPath)
		return
	}
	
	// 复制到标准位置
	destDir := "/etc/openvpn/configs"
	os.MkdirAll(destDir, 0755)
	
	destPath := filepath.Join(destDir, filepath.Base(ovpnPath))
	input, err := ioutil.ReadFile(ovpnPath)
	if err != nil {
		fmt.Printf("❌ 读取文件失败: %v\n", err)
		return
	}
	
	if err := ioutil.WriteFile(destPath, input, 0644); err != nil {
		fmt.Printf("❌ 复制文件失败: %v\n", err)
		return
	}
	
	fmt.Printf("✓ 配置文件已复制到 %s\n", destPath)
	
	// 是否需要认证
	fmt.Print("\n是否需要用户名密码认证? (y/n): ")
	needAuth, _ := reader.ReadString('\n')
	needAuth = strings.TrimSpace(strings.ToLower(needAuth))
	
	authFile := ""
	if needAuth == "y" || needAuth == "yes" {
		fmt.Print("用户名: ")
		username, _ := reader.ReadString('\n')
		username = strings.TrimSpace(username)
		
		fmt.Print("密码: ")
		password, _ := reader.ReadString('\n')
		password = strings.TrimSpace(password)
		
		// 创建认证文件
		os.MkdirAll("/etc/openvpn/auth", 0755)
		authFile = fmt.Sprintf("/etc/openvpn/auth/%s.txt", name)
		
		authContent := fmt.Sprintf("%s\n%s\n", username, password)
		if err := ioutil.WriteFile(authFile, []byte(authContent), 0600); err != nil {
			fmt.Printf("❌ 创建认证文件失败: %v\n", err)
			return
		}
		fmt.Printf("✓ 认证文件已创建: %s\n", authFile)
	}
	
	// TUN 设备名
	fmt.Print("\nTUN 设备名称 (例如 tun10): ")
	tunDevice, _ := reader.ReadString('\n')
	tunDevice = strings.TrimSpace(tunDevice)
	if tunDevice == "" {
		tunDevice = "tun10"
	}
	
	// 加载现有配置
	cfg, err := config.LoadConfig(configFile)
	if err != nil {
		cfg = &config.Config{
			LogLevel: "info",
			LogFile:  "/var/log/openvpn-manager.log",
		}
	}
	
	// 添加新实例
	newInstance := config.Instance{
		Name:       name,
		ConfigPath: destPath,
		AuthFile:   authFile,
		TunDevice:  tunDevice,
		Enabled:    true,
	}
	
	cfg.Instances = append(cfg.Instances, newInstance)
	
	// 保存配置
	if err := saveConfig(cfg); err != nil {
		fmt.Printf("\n❌ 保存配置失败: %v\n", err)
		return
	}
	
	fmt.Println("\n✅ 配置添加成功！")
	fmt.Println("\n使用以下命令启动:")
	fmt.Println("  openvpn-manager start")
}

func removeConfig(reader *bufio.Reader) {
	cfg, err := config.LoadConfig(configFile)
	if err != nil {
		fmt.Printf("\n❌ 无法加载配置: %v\n", err)
		return
	}
	
	if len(cfg.Instances) == 0 {
		fmt.Println("\n❌ 没有可删除的配置")
		return
	}
	
	showConfigs()
	
	fmt.Print("\n输入要删除的配置编号: ")
	numStr, _ := reader.ReadString('\n')
	numStr = strings.TrimSpace(numStr)
	
	var num int
	fmt.Sscanf(numStr, "%d", &num)
	
	if num < 1 || num > len(cfg.Instances) {
		fmt.Println("❌ 无效编号")
		return
	}
	
	// 确认删除
	toDelete := cfg.Instances[num-1]
	fmt.Printf("\n确认删除 '%s'? (y/n): ", toDelete.Name)
	confirm, _ := reader.ReadString('\n')
	confirm = strings.TrimSpace(strings.ToLower(confirm))
	
	if confirm != "y" && confirm != "yes" {
		fmt.Println("取消删除")
		return
	}
	
	// 删除配置
	cfg.Instances = append(cfg.Instances[:num-1], cfg.Instances[num:]...)
	
	if err := saveConfig(cfg); err != nil {
		fmt.Printf("\n❌ 保存配置失败: %v\n", err)
		return
	}
	
	fmt.Println("\n✅ 配置已删除")
}

func toggleConfig(reader *bufio.Reader) {
	cfg, err := config.LoadConfig(configFile)
	if err != nil {
		fmt.Printf("\n❌ 无法加载配置: %v\n", err)
		return
	}
	
	if len(cfg.Instances) == 0 {
		fmt.Println("\n❌ 没有可用的配置")
		return
	}
	
	showConfigs()
	
	fmt.Print("\n输入要启用/禁用的配置编号: ")
	numStr, _ := reader.ReadString('\n')
	numStr = strings.TrimSpace(numStr)
	
	var num int
	fmt.Sscanf(numStr, "%d", &num)
	
	if num < 1 || num > len(cfg.Instances) {
		fmt.Println("❌ 无效编号")
		return
	}
	
	// 切换状态
	cfg.Instances[num-1].Enabled = !cfg.Instances[num-1].Enabled
	
	if err := saveConfig(cfg); err != nil {
		fmt.Printf("\n❌ 保存配置失败: %v\n", err)
		return
	}
	
	status := "启用"
	if !cfg.Instances[num-1].Enabled {
		status = "禁用"
	}
	fmt.Printf("\n✅ 配置 '%s' 已%s\n", cfg.Instances[num-1].Name, status)
}

func saveConfig(cfg *config.Config) error {
	data, err := yaml.Marshal(cfg)
	if err != nil {
		return err
	}
	
	return ioutil.WriteFile(configFile, data, 0644)
}
