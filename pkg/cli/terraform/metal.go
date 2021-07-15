package terraform

import "fmt"

type MetalNode struct {
	IP              string   `json:"ip"`
	InternalAddress string   `json:"internal-address,omitempty"`
	PoolName        string   `json:"pool-name"`
	PoolType        PoolType `json:"pool-type"`
}

type Metal struct {
	*Common
	MainNode            *MetalNode   `json:"k8s_master_node"`
	WorkerNodes         []*MetalNode `json:"k8s_workers"`
	RebootGPUNodes      bool         `json:"reboot_gpu_nodes,omitempty"`
	Sans                []string     `json:"k8s_sans,omitempty"`
	SetupDocker         bool         `json:"setup_docker,omitempty"`
	SetupNvidia         bool         `json:"setup_nvidia,omitempty"`
	SharedStoragePath   string       `json:"shared_storage_path,omitempty"`
	SharedStorageServer string       `json:"shared_storage_server,omitempty"`
	SSHKeyPath          string       `json:"ssh_key_path,omitempty"`
	SSHUser             string       `json:"ssh_user,omitempty"`
}

func NewMetal(version string) *Metal {
	metal := Metal{
		Common:      NewCommon(),
		MainNode:    NewMetalNode(),
		WorkerNodes: make([]*MetalNode, 0),
		SSHKeyPath:  "~/.ssh/id_rsa",
		SSHUser:     "ubuntu",
	}

	refVersion := "master"
	if version != "latest" && version != "" {
		refVersion = version
	}
	metal.TerraformSource = fmt.Sprintf("%s?ref=%s/gradient-metal", SourcePrefix, refVersion)
	return &metal
}

func NewMetalNode() *MetalNode {
	return &MetalNode{
		PoolType: PoolTypeGPU,
	}
}

func MetalPoolName(poolType PoolType) string {
	switch poolType {
	case PoolTypeCPU:
		return "metal-cpu"
	case PoolTypeGPU:
		return "metal-gpu"
	}

	return ""
}

func (m *MetalNode) UpdatePool(poolType PoolType) {
	m.PoolType = poolType
	m.PoolName = MetalPoolName(poolType)
}
