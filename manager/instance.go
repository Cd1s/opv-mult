package manager

import (
	"bufio"
	"fmt"
	"log"
	"os/exec"
	"strings"
	"sync"
	"time"

	"github.com/Cd1s/opv-mult/config"
)

// Instance represents a running OpenVPN instance
type Instance struct {
	Config    config.Instance
	Process   *exec.Cmd
	Status    string
	StartTime time.Time
	IP        string
	mu        sync.Mutex
}

// NewInstance creates a new OpenVPN instance
func NewInstance(cfg config.Instance) *Instance {
	return &Instance{
		Config: cfg,
		Status: "stopped",
	}
}

// Start starts the OpenVPN instance
func (i *Instance) Start() error {
	i.mu.Lock()
	defer i.mu.Unlock()

	if i.Status == "running" {
		return fmt.Errorf("instance %s is already running", i.Config.Name)
	}

	// Build OpenVPN command
	args := []string{
		"--config", i.Config.ConfigPath,
		"--dev", i.Config.TunDevice,
		"--dev-type", "tun",
		"--log", fmt.Sprintf("/var/log/openvpn-%s.log", i.Config.TunDevice),
		"--daemon",
		"--writepid", fmt.Sprintf("/var/run/openvpn-%s.pid", i.Config.TunDevice),
	}

	// Add auth file if specified
	if i.Config.AuthFile != "" {
		args = append(args, "--auth-user-pass", i.Config.AuthFile)
	}

	// Create command
	i.Process = exec.Command("openvpn", args...)

	// Start the process
	if err := i.Process.Start(); err != nil {
		return fmt.Errorf("failed to start OpenVPN: %w", err)
	}

	i.Status = "running"
	i.StartTime = time.Now()

	log.Printf("Started OpenVPN instance: %s (TUN: %s, PID: %d)", 
		i.Config.Name, i.Config.TunDevice, i.Process.Process.Pid)

	// Wait a bit for the TUN device to come up
	time.Sleep(2 * time.Second)

	// Try to get the IP address
	i.updateIP()

	return nil
}

// Stop stops the OpenVPN instance
func (i *Instance) Stop() error {
	i.mu.Lock()
	defer i.mu.Unlock()

	if i.Status != "running" {
		return fmt.Errorf("instance %s is not running", i.Config.Name)
	}

	// Kill the process
	if i.Process != nil && i.Process.Process != nil {
		if err := i.Process.Process.Kill(); err != nil {
			return fmt.Errorf("failed to kill process: %w", err)
		}
		i.Process.Wait()
	}

	i.Status = "stopped"
	log.Printf("Stopped OpenVPN instance: %s", i.Config.Name)

	return nil
}

// IsRunning checks if the instance is running
func (i *Instance) IsRunning() bool {
	i.mu.Lock()
	defer i.mu.Unlock()
	return i.Status == "running"
}

// IsHealthy checks if the instance is healthy
func (i *Instance) IsHealthy() bool {
	if !i.IsRunning() {
		return false
	}

	// Check if TUN device exists
	cmd := exec.Command("ip", "link", "show", i.Config.TunDevice)
	if err := cmd.Run(); err != nil {
		return false
	}

	return true
}

// updateIP gets the IP address of the TUN device
func (i *Instance) updateIP() {
	cmd := exec.Command("ip", "addr", "show", i.Config.TunDevice)
	output, err := cmd.Output()
	if err != nil {
		return
	}

	// Parse the output to get the IP address
	scanner := bufio.NewScanner(strings.NewReader(string(output)))
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if strings.HasPrefix(line, "inet ") {
			parts := strings.Fields(line)
			if len(parts) >= 2 {
				i.IP = parts[1]
				break
			}
		}
	}
}

// GetStatus returns the current status information
func (i *Instance) GetStatus() InstanceStatus {
	i.mu.Lock()
	defer i.mu.Unlock()

	i.updateIP()

	uptime := time.Duration(0)
	if i.Status == "running" {
		uptime = time.Since(i.StartTime)
	}

	return InstanceStatus{
		Name:      i.Config.Name,
		Status:    i.Status,
		TunDevice: i.Config.TunDevice,
		IP:        i.IP,
		Uptime:    uptime,
	}
}

// InstanceStatus represents the status of an instance
type InstanceStatus struct {
	Name      string
	Status    string
	TunDevice string
	IP        string
	Uptime    time.Duration
}
