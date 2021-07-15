package terraform

import (
	"fmt"
	"strings"

	"github.com/Paperspace/paperspace-go"
)

type Common struct {
	ArtifactsAccessKeyID           string            `json:"artifacts_access_key_id"`
	ArtifactsObjectStorageEndpoint string            `json:"artifacts_object_storage_endpoint,omitempty"`
	ArtifactsPath                  string            `json:"artifacts_path"`
	ArtifactsRegion                string            `json:"artifacts_region,omitempty"`
	ArtifactsSecretAccessKey       string            `json:"artifacts_secret_access_key"`
	ClusterAPIKey                  string            `json:"cluster_apikey"`
	ClusterHandle                  string            `json:"cluster_handle"`
	Domain                         string            `json:"domain"`
	GradientProcessingChart        string            `json:"gradient_processing_chart,omitempty"`
	GradientProcessingVersion      string            `json:"gradient_processing_version,omitempty"`
	LetsEncryptDNSName             string            `json:"letsencrypt_dns_name,omitempty"`
	LetsEncryptDNSSettings         map[string]string `json:"letsencrypt_dns_settings,omitempty"`
	Name                           string            `json:"name"`
	PublicKeyPath                  string            `json:"public_key_path,omitempty"`
	SharedStoragePath              string            `json:"shared_storage_path,omitempty"`
	SharedStorageServer            string            `json:"shared_storage_server,omitempty"`
	SharedStorageType              string            `json:"shared_storage_type,omitempty"`
	TerraformSource                string            `json:"source"`
	TerraformSourceVersion         string            `json:"version,omitempty"`
	TLSCert                        string            `json:"tls_cert,omitempty"`
	TLSKey                         string            `json:"tls_key,omitempty"`
}

func NewCommon() *Common {
	return &Common{
		ArtifactsRegion: "us-east-1",
	}
}

func (c *Common) GetTLSCert() string {
	if c.TLSCert == "" {
		return ""
	}

	return StringFileUnwrap(c.TLSCert)
}

func (c *Common) GetTLSKey() string {
	if c.TLSKey == "" {
		return ""
	}

	return StringFileUnwrap(c.TLSKey)
}

func (c *Common) SetTLSCert(value string) {
	c.TLSCert = StringFileWrap(value)
}

func (c *Common) SetTLSKey(value string) {
	c.TLSKey = StringFileWrap(value)
}
func (c *Common) HasValidArtifactsStorage() bool {
	if c.ArtifactsAccessKeyID == "" {
		return false
	}
	if c.ArtifactsPath == "" {
		return false
	}
	if c.ArtifactsRegion == "" {
		return false
	}
	if c.ArtifactsSecretAccessKey == "" {
		return false
	}
	return true
}

func (c *Common) HasValidLetsEncrypt() bool {
	if c.LetsEncryptDNSName != "" && len(c.LetsEncryptDNSSettings) > 0 {
		return true
	}

	return false
}

func (c *Common) HasValidTLS() bool {
	if c.TLSCert != "" && c.TLSKey != "" {
		return true
	}

	return false
}

func (c *Common) HasValidSSL() bool {
	if c.HasValidTLS() {
		return true
	}

	if c.HasValidLetsEncrypt() {
		return true
	}

	return false
}

func (c *Common) IsValid() bool {
	if !c.HasValidArtifactsStorage() {
		return false
	}
	if c.ClusterAPIKey == "" {
		return false
	}
	if c.ClusterHandle == "" {
		return false
	}
	if c.Domain == "" {
		return false
	}
	if c.Name == "" {
		return false
	}
	if c.SharedStoragePath == "" {
		return false
	}
	if (c.TLSCert == "" || c.TLSKey == "") && (c.LetsEncryptDNSName == "" || len(c.LetsEncryptDNSSettings) == 0) {
		return false
	}

	return true
}

func (c *Common) UpdateFromCluster(cluster *paperspace.Cluster) {
	c.ArtifactsAccessKeyID = cluster.S3Credential.AccessKey
	c.ArtifactsPath = fmt.Sprintf("s3://%s", cluster.S3Credential.Bucket)
	c.ArtifactsSecretAccessKey = cluster.S3Credential.SecretKey

	c.ClusterAPIKey = cluster.APIToken.Key
	c.ClusterHandle = cluster.ID
	c.Domain = cluster.Domain
	c.Name = strings.ReplaceAll(cluster.Name, " ", "-")
}

func (c *Common) UpdateSourcePrefix(prefix string, platform paperspace.ClusterPlatformType) {
	var suffix string
	switch platform {
	case paperspace.ClusterPlatformAWS:
		suffix = "gradient-aws"
	case paperspace.ClusterPlatformMetal:
		suffix = "gradient-metal"
	}

	c.TerraformSource = fmt.Sprintf("%s/%s", prefix, suffix)
}

func StringFileWrap(value string) string {
	return fmt.Sprintf("%s%s%s", "${file(\"", value, "\")}")
}

func StringFileUnwrap(value string) string {
	formattedValue := strings.TrimPrefix(value, "${file(\"")
	return strings.TrimSuffix(formattedValue, "\")}")
}
