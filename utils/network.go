package utils

import (
	"bufio"
	"fmt"
	"os/exec"
	"strings"
)

// GetTunIP returns the IP address of a TUN device
func GetTunIP(deviceName string) (string, error) {
	cmd := exec.Command("ip", "addr", "show", deviceName)
	output, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("failed to get IP for %s: %w", deviceName, err)
	}

	// Parse the output to get the IP address
	scanner := bufio.NewScanner(strings.NewReader(string(output)))
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if strings.HasPrefix(line, "inet ") {
			parts := strings.Fields(line)
			if len(parts) >= 2 {
				return parts[1], nil
			}
		}
	}

	return "", fmt.Errorf("no IP address found for %s", deviceName)
}

// TunExists checks if a TUN device exists
func TunExists(deviceName string) bool {
	cmd := exec.Command("ip", "link", "show", deviceName)
	return cmd.Run() == nil
}

// ListTunDevices returns a list of all TUN devices
func ListTunDevices() ([]string, error) {
	cmd := exec.Command("ip", "link", "show")
	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to list network devices: %w", err)
	}

	var tunDevices []string
	scanner := bufio.NewScanner(strings.NewReader(string(output)))
	for scanner.Scan() {
		line := scanner.Text()
		if strings.Contains(line, "tun") && strings.Contains(line, ":") {
			parts := strings.Fields(line)
			if len(parts) >= 2 {
				deviceName := strings.TrimSuffix(parts[1], ":")
				if strings.HasPrefix(deviceName, "tun") {
					tunDevices = append(tunDevices, deviceName)
				}
			}
		}
	}

	return tunDevices, nil
}
