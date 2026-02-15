package cmd

import (
	"fmt"
	"log"

	"github.com/Cd1s/opv-mult/utils"
	"github.com/spf13/cobra"
)

var listCmd = &cobra.Command{
	Use:   "list",
	Short: "List all TUN devices",
	Long:  `List all TUN devices and show how to configure them in Sing-box.`,
	Run: func(cmd *cobra.Command, args []string) {
		setupLogging()

		mgr, err := createManager()
		if err != nil {
			log.Fatalf("Failed to create manager: %v", err)
		}

		statuses := mgr.GetAllStatus()

		fmt.Println("\nAvailable TUN Devices for Sing-box")
		fmt.Println("===================================")

		for _, status := range statuses {
			exists := utils.TunExists(status.TunDevice)
			statusStr := "❌ Not Running"
			if exists && status.Status == "running" {
				statusStr = "✓ Running"
			}

			fmt.Printf("\n%s -> %s (%s)", status.TunDevice, status.Name, statusStr)
			if status.IP != "" {
				fmt.Printf(" [%s]", status.IP)
			}
			fmt.Println()
		}

		fmt.Println("\n\nSing-box 配置示例：")
		fmt.Println("==================")
		fmt.Println(`{
  "outbounds": [`)

		for i, status := range statuses {
			comma := ","
			if i == len(statuses)-1 {
				comma = ""
			}
			fmt.Printf(`    {
      "type": "direct",
      "tag": "out-%s",
      "bind_interface": "%s"
    }%s
`, status.Name, status.TunDevice, comma)
		}

		fmt.Println(`  ]
}`)

		fmt.Println("\n使用提示：")
		fmt.Println("在 Sing-box 的路由规则中使用上述出站标签，例如：")
		fmt.Println(`{
  "route": {
    "rules": [
      {
        "domain": ["netflix.com"],
        "outbound": "out-us-server-1"
      }
    ]
  }
}`)
		fmt.Println()
	},
}

func init() {
	rootCmd.AddCommand(listCmd)
}
