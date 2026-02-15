package config

import (
	"fmt"
	"os"

	"gopkg.in/yaml.v3"
)

// Config represents the main configuration structure
type Config struct {
	LogLevel string     `yaml:"log_level"`
	LogFile  string     `yaml:"log_file"`
	Instances []Instance `yaml:"instances"`
}

// Instance represents a single OpenVPN instance configuration
type Instance struct {
	Name       string `yaml:"name"`
	ConfigPath string `yaml:"config"`
	AuthFile   string `yaml:"auth_file"`
	TunDevice  string `yaml:"tun_device"`
	Enabled    bool   `yaml:"enabled"`
}

// LoadConfig loads and parses the YAML configuration file
func LoadConfig(configPath string) (*Config, error) {
	data, err := os.ReadFile(configPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read config file: %w", err)
	}

	var config Config
	if err := yaml.Unmarshal(data, &config); err != nil {
		return nil, fmt.Errorf("failed to parse config file: %w", err)
	}

	// Validate configuration
	if err := config.Validate(); err != nil {
		return nil, fmt.Errorf("invalid configuration: %w", err)
	}

	return &config, nil
}

// Validate checks if the configuration is valid
func (c *Config) Validate() error {
	if len(c.Instances) == 0 {
		return fmt.Errorf("no instances defined in configuration")
	}

	tunDevices := make(map[string]bool)
	for i, instance := range c.Instances {
		if instance.Name == "" {
			return fmt.Errorf("instance %d: name is required", i)
		}
		if instance.ConfigPath == "" {
			return fmt.Errorf("instance %s: config path is required", instance.Name)
		}
		if instance.TunDevice == "" {
			return fmt.Errorf("instance %s: tun_device is required", instance.Name)
		}

		// Check for duplicate TUN devices
		if tunDevices[instance.TunDevice] {
			return fmt.Errorf("duplicate tun_device: %s", instance.TunDevice)
		}
		tunDevices[instance.TunDevice] = true

		// Check if config file exists
		if _, err := os.Stat(instance.ConfigPath); os.IsNotExist(err) {
			return fmt.Errorf("instance %s: config file not found: %s", instance.Name, instance.ConfigPath)
		}

		// Check if auth file exists (if specified)
		if instance.AuthFile != "" {
			if _, err := os.Stat(instance.AuthFile); os.IsNotExist(err) {
				return fmt.Errorf("instance %s: auth file not found: %s", instance.Name, instance.AuthFile)
			}
		}
	}

	return nil
}

// GetEnabledInstances returns only the enabled instances
func (c *Config) GetEnabledInstances() []Instance {
	var enabled []Instance
	for _, instance := range c.Instances {
		if instance.Enabled {
			enabled = append(enabled, instance)
		}
	}
	return enabled
}
