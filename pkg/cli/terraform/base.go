package terraform

import (
	"github.com/Paperspace/paperspace-go"
)

var SourcePrefix = "github.com/Paperspace/gradient-installer"
var SupportedClusterPlatformTypes = []paperspace.ClusterPlatformType{paperspace.ClusterPlatformAWS, paperspace.ClusterPlatformDGX, paperspace.ClusterPlatformMetal}

type PoolType string

const (
	PoolTypeCPU PoolType = "cpu"
	PoolTypeGPU PoolType = "gpu"
)

type Terraform struct {
	Modules           *TerraformModules  `json:"module"`
	Outputs           *TerraformOutputs  `json:"output,omitempty"`
	TerraformProvider *TerraformProvider `json:"terraform"`
}

func NewTerraform(platform paperspace.ClusterPlatformType, version string) *Terraform {
	terraformModules := TerraformModules{}
	var terraformOutputs *TerraformOutputs

	switch platform {
	case paperspace.ClusterPlatformAWS:
		terraformModules.AWS = NewAWS(version)
		terraformOutputs = &TerraformOutputs{
			DNSCName: &TerraformOutput{
				Value: "${module.gradient_aws.elb_hostname}",
			},
		}
	case paperspace.ClusterPlatformMetal:
		terraformModules.Metal = NewMetal(version)
	}

	terraform := Terraform{
		Modules:           &terraformModules,
		Outputs:           terraformOutputs,
		TerraformProvider: NewTerraformProvider(),
	}

	return &terraform
}

func (t *Terraform) GetCommon(platform paperspace.ClusterPlatformType) *Common {
	switch platform {
	case paperspace.ClusterPlatformAWS:
		return t.Modules.AWS.Common
	case paperspace.ClusterPlatformMetal:
		return t.Modules.Metal.Common
	}

	return nil
}

func (t *Terraform) HasValidAWS() bool {
	if t.Modules == nil || t.Modules.AWS == nil {
		return false
	}
	return false
}

func (t *Terraform) HasValidMetal() bool {
	if t.Modules == nil || t.Modules.Metal == nil {
		return false
	}

	if t.Modules.Metal.MainNode == nil {
		return false
	}

	if t.Modules.Metal.MainNode.IP == "" {
		return false
	}

	if t.Modules.Metal.MainNode.PoolType == "" {
		return false
	}

	for _, workerNode := range t.Modules.Metal.WorkerNodes {
		if workerNode.IP == "" {
			return false
		}
		if workerNode.PoolType == "" {
			return false
		}
	}

	return true
}

func (t *Terraform) HasValidTerraformProvider() bool {
	if t.TerraformProvider == nil || t.TerraformProvider.Backends == nil || t.TerraformProvider.Backends.S3 == nil {
		return false
	}

	if t.TerraformProvider.Backends.S3.AccessKeyID == "" {
		return false
	}
	if t.TerraformProvider.Backends.S3.Bucket == "" {
		return false
	}
	if t.TerraformProvider.Backends.S3.Key == "" {
		return false
	}
	if t.TerraformProvider.Backends.S3.Region == "" {
		return false
	}
	if t.TerraformProvider.Backends.S3.SecretAccessKey == "" {
		return false
	}

	return true
}

func IsSupportedPlatform(platform paperspace.ClusterPlatformType) bool {
	for _, supportedPlatform := range SupportedClusterPlatformTypes {
		if supportedPlatform == platform {
			return true
		}
	}

	return false
}
