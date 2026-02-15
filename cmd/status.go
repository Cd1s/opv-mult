package cmd

import (
	"fmt"
	"log"

	"github.com/spf13/cobra"
)

var statusCmd = &cobra.Command{
	Use:   "status",
	Short: "Show status of all OpenVPN instances",
	Long:  `Display the current status of all configured OpenVPN instances.`,
	Run: func(cmd *cobra.Command, args []string) {
		setupLogging()

		mgr, err := createManager()
		if err != nil {
			log.Fatalf("Failed to create manager: %v", err)
		}

		statuses := mgr.GetAllStatus()

		fmt.Println("\nOpenVPN Manager Status")
		fmt.Println("======================")

		for _, status := range statuses {
			fmt.Printf("\nInstance: %s\n", status.Name)
			fmt.Printf("  Status:     %s\n", status.Status)
			fmt.Printf("  TUN Device: %s\n", status.TunDevice)
			if status.IP != "" {
				fmt.Printf("  IP Address: %s\n", status.IP)
			}
			if status.Status == "running" {
				fmt.Printf("  Uptime:     %s\n", formatDuration(status.Uptime))
			}
		}

		fmt.Println()
	},
}

func init() {
	rootCmd.AddCommand(statusCmd)
}

// formatDuration formats a duration in a human-readable way
func formatDuration(d interface{}) string {
	// Simple implementation - you can enhance this
	return fmt.Sprintf("%v", d)
}
