package cmd

import (
	"fmt"
	"log"

	"github.com/spf13/cobra"
)

var startCmd = &cobra.Command{
	Use:   "start",
	Short: "Start all OpenVPN instances",
	Long:  `Start all enabled OpenVPN instances defined in the configuration file.`,
	Run: func(cmd *cobra.Command, args []string) {
		setupLogging()

		log.Println("Starting OpenVPN Manager...")

		mgr, err := createManager()
		if err != nil {
			log.Fatalf("Failed to create manager: %v", err)
		}

		if err := mgr.StartAll(); err != nil {
			log.Fatalf("Failed to start instances: %v", err)
		}

		fmt.Println("\n✓ All OpenVPN instances started successfully!")
		fmt.Println("\nRun 'openvpn-manager status' to check the status")
		fmt.Println("Run 'openvpn-manager list' to see TUN devices for Sing-box")
	},
}

func init() {
	rootCmd.AddCommand(startCmd)
}
