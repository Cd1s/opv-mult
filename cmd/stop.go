package cmd

import (
	"fmt"
	"log"

	"github.com/spf13/cobra"
)

var stopCmd = &cobra.Command{
	Use:   "stop",
	Short: "Stop all OpenVPN instances",
	Long:  `Stop all running OpenVPN instances.`,
	Run: func(cmd *cobra.Command, args []string) {
		setupLogging()

		log.Println("Stopping OpenVPN instances...")

		mgr, err := createManager()
		if err != nil {
			log.Fatalf("Failed to create manager: %v", err)
		}

		if err := mgr.StopAll(); err != nil {
			log.Fatalf("Failed to stop instances: %v", err)
		}

		fmt.Println("\n✓ All OpenVPN instances stopped successfully!")
	},
}

func init() {
	rootCmd.AddCommand(stopCmd)
}
