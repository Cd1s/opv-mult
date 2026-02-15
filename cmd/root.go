package cmd

import (
	"fmt"
	"log"
	"os"

	"github.com/Cd1s/opv-mult/config"
	"github.com/Cd1s/opv-mult/manager"
	"github.com/spf13/cobra"
)

var (
	configFile string
	// Forward declaration - actual implementation in config.go
	runInteractiveConfig func()
)

// rootCmd represents the base command
var rootCmd = &cobra.Command{
	Use:   "openvpn-manager",
	Short: "Manage multiple OpenVPN instances",
	Long: `OpenVPN Manager - A tool to manage multiple OpenVPN connections simultaneously.
Each connection creates an independent TUN device that can be used with Sing-box.`,
	Run: func(cmd *cobra.Command, args []string) {
		// If no subcommand provided, show interactive menu
		if runInteractiveConfig != nil {
			runInteractiveConfig()
		} else {
			cmd.Help()
		}
	},
}

// Execute runs the root command
func Execute() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}

func init() {
	rootCmd.PersistentFlags().StringVarP(&configFile, "config", "c", "/etc/openvpn-manager/config.yaml", "config file path")
}

// loadConfig is a helper function to load configuration
func loadConfig() (*config.Config, error) {
	cfg, err := config.LoadConfig(configFile)
	if err != nil {
		return nil, fmt.Errorf("failed to load config: %w", err)
	}
	return cfg, nil
}

// createManager creates a new manager instance
func createManager() (*manager.Manager, error) {
	cfg, err := loadConfig()
	if err != nil {
		return nil, err
	}

	mgr := manager.NewManager(cfg)
	if err := mgr.Initialize(); err != nil {
		return nil, fmt.Errorf("failed to initialize manager: %w", err)
	}

	return mgr, nil
}

// setupLogging configures logging
func setupLogging() {
	log.SetFlags(log.LstdFlags | log.Lshortfile)
}
