package manager

import (
	"fmt"
	"log"
	"sync"

	"github.com/Cd1s/opv-mult/config"
)

// Manager manages multiple OpenVPN instances
type Manager struct {
	instances []*Instance
	config    *config.Config
	mu        sync.Mutex
}

// NewManager creates a new OpenVPN manager
func NewManager(cfg *config.Config) *Manager {
	return &Manager{
		config:    cfg,
		instances: make([]*Instance, 0),
	}
}

// Initialize creates instances from configuration
func (m *Manager) Initialize() error {
	m.mu.Lock()
	defer m.mu.Unlock()

	enabledInstances := m.config.GetEnabledInstances()
	if len(enabledInstances) == 0 {
		return fmt.Errorf("no enabled instances found in configuration")
	}

	for _, cfg := range enabledInstances {
		instance := NewInstance(cfg)
		m.instances = append(m.instances, instance)
	}

	log.Printf("Initialized %d OpenVPN instances", len(m.instances))
	return nil
}

// StartAll starts all configured instances
func (m *Manager) StartAll() error {
	m.mu.Lock()
	defer m.mu.Unlock()

	var errors []error

	for _, instance := range m.instances {
		log.Printf("Starting instance: %s", instance.Config.Name)
		if err := instance.Start(); err != nil {
			errors = append(errors, fmt.Errorf("failed to start %s: %w", instance.Config.Name, err))
		}
	}

	if len(errors) > 0 {
		return fmt.Errorf("some instances failed to start: %v", errors)
	}

	log.Printf("Successfully started all %d instances", len(m.instances))
	return nil
}

// StopAll stops all running instances
func (m *Manager) StopAll() error {
	m.mu.Lock()
	defer m.mu.Unlock()

	var errors []error

	for _, instance := range m.instances {
		if instance.IsRunning() {
			log.Printf("Stopping instance: %s", instance.Config.Name)
			if err := instance.Stop(); err != nil {
				errors = append(errors, fmt.Errorf("failed to stop %s: %w", instance.Config.Name, err))
			}
		}
	}

	if len(errors) > 0 {
		return fmt.Errorf("some instances failed to stop: %v", errors)
	}

	log.Printf("Successfully stopped all instances")
	return nil
}

// GetAllStatus returns the status of all instances
func (m *Manager) GetAllStatus() []InstanceStatus {
	m.mu.Lock()
	defer m.mu.Unlock()

	statuses := make([]InstanceStatus, 0, len(m.instances))
	for _, instance := range m.instances {
		statuses = append(statuses, instance.GetStatus())
	}

	return statuses
}

// GetInstance returns an instance by name
func (m *Manager) GetInstance(name string) (*Instance, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	for _, instance := range m.instances {
		if instance.Config.Name == name {
			return instance, nil
		}
	}

	return nil, fmt.Errorf("instance not found: %s", name)
}

// MonitorAndRestart monitors all instances and restarts failed ones
func (m *Manager) MonitorAndRestart() {
	for {
		m.mu.Lock()
		for _, instance := range m.instances {
			if !instance.IsHealthy() && instance.Status == "running" {
				log.Printf("Instance %s is unhealthy, restarting...", instance.Config.Name)
				instance.Stop()
				if err := instance.Start(); err != nil {
					log.Printf("Failed to restart instance %s: %v", instance.Config.Name, err)
				}
			}
		}
		m.mu.Unlock()

		// Check every 30 seconds
		// time.Sleep(30 * time.Second)
		// Note: For daemon mode, uncomment the line above
	}
}
