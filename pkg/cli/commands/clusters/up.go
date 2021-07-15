package clusters

import (
	"encoding/json"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"regexp"

	"github.com/Paperspace/gradient-installer/pkg/cli"
	"github.com/Paperspace/gradient-installer/pkg/cli/config"
	"github.com/Paperspace/gradient-installer/pkg/cli/terraform"
	"github.com/Paperspace/paperspace-go"
	"github.com/manifoldco/promptui"
	"github.com/spf13/cobra"
)

var TerraformTFName = "main.tf"

func createTerraformMetalNode(terraformMetalNode *terraform.MetalNode, prefix string, required bool) (*terraform.MetalNode, error) {
	if terraformMetalNode == nil {
		terraformMetalNode = terraform.NewMetalNode()
	}

	ipPrompt := cli.Prompt{
		Label:    "IP",
		Value:    terraformMetalNode.IP,
		Required: required,
	}

	internalAddressPrompt := cli.Prompt{
		Label: "Internal IP (if applicable)",
		Value: terraformMetalNode.InternalAddress,
	}

	poolTypeSelect := promptui.Select{
		Label: "Type",
		Items: []string{string(terraform.PoolTypeGPU), string(terraform.PoolTypeCPU)},
	}

	println("")
	println(cli.TextHeader(fmt.Sprintf("Add %s", prefix)))

	if err := ipPrompt.Run(); err != nil {
		return terraformMetalNode, err
	}
	if err := internalAddressPrompt.Run(); err != nil {
		return terraformMetalNode, err
	}
	_, poolType, err := poolTypeSelect.Run()
	if err != nil {
		return terraformMetalNode, err
	}

	terraformMetalNode.IP = ipPrompt.Value
	terraformMetalNode.InternalAddress = internalAddressPrompt.Value
	terraformMetalNode.UpdatePool(terraform.PoolType(poolType))

	return terraformMetalNode, nil
}

func setupMetalConfig(terraformMetal *terraform.Metal) error {
	// Typed to NFS till we support more storage types
	sharedStorageServer := cli.Prompt{
		Label:    "NFS Server",
		Required: true,
		Value:    terraformMetal.SharedStorageServer,
	}
	sharedStoragePath := cli.Prompt{
		Label:    "NFS Storage Path",
		Required: true,
		Value:    terraformMetal.SharedStoragePath,
	}
	rebootGPUNodesPrompt := cli.Prompt{
		Label:         "Reboot GPU Nodes (for NVIDIA drivers)",
		AllowedValues: cli.YesNoValues,
		Value:         cli.BoolToYesNo(terraformMetal.RebootGPUNodes),
		Required:      true,
	}
	setupDockerPrompt := cli.Prompt{
		Label:         "Setup Docker",
		Required:      true,
		AllowedValues: cli.YesNoValues,
		Value:         cli.BoolToYesNo(terraformMetal.SetupDocker),
	}
	setupNvidiaPrompt := cli.Prompt{
		Label:    "Setup NVIDIA",
		Required: true,
		Value:    cli.BoolToYesNo(terraformMetal.SetupNvidia),
	}
	sshKeyPathPrompt := cli.Prompt{
		Label:    "SSH Private Key Path",
		Required: true,
		Value:    terraformMetal.SSHKeyPath,
	}
	sshUserPrompt := cli.Prompt{
		Label:    "SSH User",
		Required: true,
		Value:    terraformMetal.SSHUser,
	}
	if err := sharedStorageServer.Run(); err != nil {
		return err
	}
	if err := sharedStoragePath.Run(); err != nil {
		return err
	}

	mainNode, err := createTerraformMetalNode(terraformMetal.MainNode, "Main Node", true)
	if err != nil {
		return err
	}

	workerNodes := make([]*terraform.MetalNode, 0)

	for index, workerNode := range terraformMetal.WorkerNodes {
		workerPrompt := cli.Prompt{
			Label:         fmt.Sprintf("Remove worker node %d with IP: %s?", index+1, workerNode.IP),
			HideValue:     true,
			Required:      true,
			AllowedValues: cli.YesNoValues,
		}

		println("")
		if err := workerPrompt.Run(); err != nil {
			return err
		}

		if workerPrompt.Value == "yes" {
			continue
		}

		node, err := createTerraformMetalNode(workerNode, fmt.Sprintf("Worker Node %d", index+1), true)
		if err != nil {
			return err
		}

		workerNodes = append(workerNodes, node)
	}

	for {
		workerPrompt := cli.Prompt{
			Label:         "Add a worker node?",
			Required:      true,
			HideValue:     true,
			AllowedValues: cli.YesNoValues,
		}

		println("")
		if err := workerPrompt.Run(); err != nil {
			return err
		}

		if workerPrompt.Value == "no" {
			break
		}

		node, err := createTerraformMetalNode(nil, fmt.Sprintf("Worker Node %d", len(workerNodes)+1), true)
		if err != nil {
			return err
		}

		workerNodes = append(workerNodes, node)
	}

	if err := sshUserPrompt.Run(); err != nil {
		return err
	}
	if err := sshKeyPathPrompt.Run(); err != nil {
		return err
	}
	if err := setupDockerPrompt.Run(); err != nil {
		return err
	}
	if err := setupNvidiaPrompt.Run(); err != nil {
		return err
	}

	terraformMetal.MainNode = mainNode
	terraformMetal.WorkerNodes = workerNodes
	terraformMetal.SharedStoragePath = sharedStoragePath.Value
	terraformMetal.SharedStorageServer = sharedStorageServer.Value
	terraformMetal.SetupDocker = cli.YesNoToBool(setupDockerPrompt.Value)
	terraformMetal.SetupNvidia = cli.YesNoToBool(setupNvidiaPrompt.Value)
	terraformMetal.SSHKeyPath = sshKeyPathPrompt.Value
	terraformMetal.SSHUser = sshUserPrompt.Value

	if terraformMetal.SetupNvidia {
		if err := rebootGPUNodesPrompt.Run(); err != nil {
			return err
		}

		terraformMetal.RebootGPUNodes = cli.YesNoToBool(rebootGPUNodesPrompt.Value)
	}

	return nil
}

func saveFilePath(path, destPath string) error {
	_, err := os.Stat(path)
	if err != nil {
		return err
	}

	srcFile, err := os.Open(path)
	if err != nil {
		return err
	}
	defer srcFile.Close()

	if err := os.MkdirAll(filepath.Dir(destPath), 0700); err != nil {
		return nil
	}

	destFile, err := os.Create(destPath)
	if err != nil {
		return err
	}
	defer destFile.Close()

	n, err := io.Copy(destFile, srcFile)
	if err != nil {
		return err
	}

	if n == 0 {
		return fmt.Errorf("Source file is empty: %s", path)
	}

	return nil
}

func setupSSL(terraformCommon *terraform.Common, terraformDir string) error {
	var method string

	if terraformCommon.HasValidTLS() {
		method = "cert"
	}
	if terraformCommon.HasValidLetsEncrypt() {
		method = "letsencrypt"
	}

	sslSetupSelect := promptui.Select{
		Label: "SSL Setup Method",
		Items: []string{"cert", "letsencrypt"},
	}

	println("")
	println(cli.TextHeader("Setup SSL"))

	_, method, err := sslSetupSelect.Run()
	if err != nil {
		return err
	}

	switch method {
	case "cert":
		terraformCommon.LetsEncryptDNSName = ""
		terraformCommon.LetsEncryptDNSSettings = make(map[string]string)

		tlsCertPrompt := cli.Prompt{
			Label:    "SSL Certificate Path",
			Required: true,
			Value:    terraformCommon.GetTLSCert(),
		}
		tlsKeyPrompt := cli.Prompt{
			Label:    "SSL Key Path",
			Required: true,
			Value:    terraformCommon.GetTLSKey(),
		}

		println("")
		println(cli.TextHeader("Setup SSL Certificates"))

		for {
			if err := tlsCertPrompt.Run(); err != nil {
				return err
			}

			storedTLSCert := filepath.Join(terraformDir, "ssl.cert")
			if tlsCertPrompt.Value != storedTLSCert {
				if err := saveFilePath(tlsCertPrompt.Value, storedTLSCert); err != nil {
					println("Could not save file to cluster directory, please try again")
					continue
				}
			}

			terraformCommon.SetTLSCert(storedTLSCert)
			break
		}

		for {
			if err := tlsKeyPrompt.Run(); err != nil {
				return err
			}

			storedTLSKey := filepath.Join(terraformDir, "ssl.key")
			if tlsKeyPrompt.Value != storedTLSKey {
				if err := saveFilePath(tlsKeyPrompt.Value, storedTLSKey); err != nil {
					println("Could not save file to cluster directory, please try again")
					continue
				}
			}

			terraformCommon.SetTLSKey(storedTLSKey)
			break
		}

	case "letsencrypt":
		terraformCommon.TLSCert = ""
		terraformCommon.TLSKey = ""

		letsEncryptDNSProviderPrompt := cli.Prompt{
			Label:    "DNS Provider Name",
			Required: true,
			Value:    terraformCommon.LetsEncryptDNSName,
		}

		letsEncryptDNSSettings := ""
		if len(terraformCommon.LetsEncryptDNSSettings) > 0 {
			letsEncryptDNSSettingsBytes, err := json.Marshal(terraformCommon.LetsEncryptDNSSettings)
			if err != nil {
				letsEncryptDNSSettings = ""
			} else {
				letsEncryptDNSSettings = string(letsEncryptDNSSettingsBytes)
			}
		}

		letsEncryptDNSSettingsPrompt := cli.Prompt{
			Label:    "JSON DNS Environment Variables",
			Required: true,
			Value:    string(letsEncryptDNSSettings),
		}

		println("")
		println(cli.TextHeader("Setup Let's Encrypt (see https://docs.traefik.io/v1.7/configuration/acme)"))

		if err := letsEncryptDNSProviderPrompt.Run(); err != nil {
			return err
		}

		for {
			if err := letsEncryptDNSSettingsPrompt.Run(); err != nil {
				return err
			}

			terraformCommon.LetsEncryptDNSName = letsEncryptDNSProviderPrompt.Value

			if err := json.Unmarshal([]byte(letsEncryptDNSSettingsPrompt.Value), &terraformCommon.LetsEncryptDNSSettings); err != nil {
				println("Invalid JSON, please try again")
				letsEncryptDNSSettingsPrompt.Value = ""
				continue
			}
			break
		}
	}

	return nil
}

func setupTerraformProvider(terraformProvider *terraform.TerraformProvider) error {
	useSystemS3Credentials := true

	println(cli.TextHeader("Configure an S3 bucket to store Terraform state"))
	s3AccessKeyIDPrompt := cli.Prompt{
		Label:          "Access Key ID",
		MaskShowLength: 4,
		Required:       true,
		UseMask:        true,
		Value:          terraformProvider.Backends.S3.AccessKeyID,
	}
	s3BucketPrompt := cli.Prompt{
		Label:    "Bucket",
		Required: true,
		Value:    terraformProvider.Backends.S3.Bucket,
	}
	s3KeyPrompt := cli.Prompt{
		Label:    "Key Path (secrets will be stored here)",
		Required: true,
		Value:    terraformProvider.Backends.S3.Key,
	}
	s3SecretAccessKeyPrompt := cli.Prompt{
		Label:          "Secret Access Key",
		MaskShowLength: 4,
		Required:       true,
		Value:          terraformProvider.Backends.S3.SecretAccessKey,
		UseMask:        true,
	}
	s3RegionPrompt := cli.Prompt{
		Label:    "Region",
		Required: true,
		Value:    terraformProvider.Backends.S3.Region,
	}
	s3EndpointPrompt := cli.Prompt{
		Label: "Endpoint",
		Value: terraformProvider.Backends.S3.Endpoint,
	}
	useSystemS3CredentialsPrompt := cli.Prompt{
		Label:         "Use system S3 credentials (~/.aws or environment variables)?",
		Required:      true,
		AllowedValues: cli.YesNoValues,
		Value:         cli.BoolToYesNo(useSystemS3Credentials),
	}

	if err := s3BucketPrompt.Run(); err != nil {
		return err
	}
	if err := s3KeyPrompt.Run(); err != nil {
		return err
	}
	if err := s3RegionPrompt.Run(); err != nil {
		return err
	}
	if err := s3EndpointPrompt.Run(); err != nil {
		return err
	}
	if err := useSystemS3CredentialsPrompt.Run(); err != nil {
		return err
	}

	if !cli.YesNoToBool(useSystemS3CredentialsPrompt.Value) {
		if err := s3AccessKeyIDPrompt.Run(); err != nil {
			return err
		}
		if err := s3SecretAccessKeyPrompt.Run(); err != nil {
			return err
		}

		terraformProvider.Backends.S3.AccessKeyID = s3AccessKeyIDPrompt.Value
		terraformProvider.Backends.S3.SecretAccessKey = s3SecretAccessKeyPrompt.Value
	} else {
		terraformProvider.Backends.S3.AccessKeyID = ""
		terraformProvider.Backends.S3.SecretAccessKey = ""
	}

	terraformProvider.Backends.S3.Bucket = s3BucketPrompt.Value
	terraformProvider.Backends.S3.Endpoint = s3EndpointPrompt.Value
	terraformProvider.Backends.S3.Key = s3KeyPrompt.Value
	terraformProvider.Backends.S3.Region = s3RegionPrompt.Value

	return nil
}

func NewClusterUpCommand(version string) *cobra.Command {
	var autoApprove bool
	var reinstall bool

	command := cobra.Command{
		Use:   "up [CLUSTER_ID]",
		Args:  cobra.MaximumNArgs(1),
		Short: "Setup cluster",
		RunE: func(cmd *cobra.Command, args []string) error {
			var id string

			// Prepare args
			client := cli.FromContext(cmd)
			if len(args) > 0 {
				id = args[0]
			} else {
				var err error
				id, err = ClusterRegister(client, "")
				if err != nil {
					return err
				}
			}
			terraformDir := filepath.Join("clusters", id)

			// Check if cluster is valid
			checkCluster, err := client.GetCluster(id, paperspace.ClusterGetParams{})
			if err != nil {
				return err
			}
			if !terraform.IsSupportedPlatform(checkCluster.Platform) {
				return fmt.Errorf("Platform '%s' is not currently supported by %s", checkCluster.Platform, cli.Name)
			}

			// Update cluster to regenerate cluster API key
			updateClusterParams := paperspace.ClusterUpdateParams{
				ID:             id,
				CreateNewToken: true,
			}
			cluster, err := client.UpdateCluster(id, updateClusterParams)
			if err != nil {
				return err
			}
			terraformInstance := terraform.NewTerraform(cluster.Platform, version)

			// Load existing config values if exists
			if err := config.LoadConfigIfExists(terraformDir, TerraformTFName, terraformInstance); err != nil {
				return err
			}

			// Check if terraform Provider values are valid
			if terraformInstance.TerraformProvider.Backends.S3.Key == "" {
				terraformInstance.TerraformProvider.Backends.S3.Key = fmt.Sprintf("gradient/%s.tfstate", id)
			}

			if reinstall || !terraformInstance.HasValidTerraformProvider() {
				if err = setupTerraformProvider(terraformInstance.TerraformProvider); err != nil {
					return err
				}
			}

			// Update cluster API values
			terraformCommon := terraformInstance.GetCommon(cluster.Platform)
			terraformCommon.UpdateFromCluster(&cluster)

			// Check SSL settings are valid
			if reinstall || !terraformCommon.HasValidSSL() {
				configDir, err := config.ConfigDirectory()
				if err != nil {
					return err
				}

				sslDir := filepath.Join(configDir, terraformDir)
				if err := setupSSL(terraformCommon, sslDir); err != nil {
					return err
				}
			}

			// Specific
			switch cluster.Platform {
			case paperspace.ClusterPlatformAWS:
			case paperspace.ClusterPlatformMetal:
				if reinstall || !terraformInstance.HasValidMetal() {
					if err := setupMetalConfig(terraformInstance.Modules.Metal); err != nil {
						return err
					}
				}
			}

			// Check for source prefix override
			sourcePrefix := os.Getenv("PAPERSPACE_TERRAFORM_PREFIX")
			if sourcePrefix != "" {
				terraformCommon.UpdateSourcePrefix(sourcePrefix, cluster.Platform)
			} else {
				if version != "latest" && version != "" {
					// Update terraform module source ref to current version
					r, err := regexp.Compile(`\?ref=v\d+\.\d+\.\d+/|\?ref=master/`)
					if err != nil {
						return err
					}
					sourceWithUpdatedVersion := r.ReplaceAllString(terraformCommon.TerraformSource, "?ref=" + version +"/")
					if sourceWithUpdatedVersion != terraformCommon.TerraformSource {
						terraformCommon.TerraformSource = sourceWithUpdatedVersion
					}
				}
			}

			// Write Config
			if err := config.WriteConfig(terraformDir, TerraformTFName, terraformInstance); err != nil {
				return err
			}

			// Terraform apply
			configPath, err := config.ConfigPath(terraformDir, TerraformTFName)
			if err != nil {
				return err
			}

			println("")
			println(cli.TextHeader("Running terraform"))
			if err := terraform.InitCommand(filepath.Dir(configPath)); err != nil {
				return err
			}
			if err := terraform.ApplyCommand(filepath.Dir(configPath), autoApprove); err != nil {
				return err
			}

			kubeconfigPath := filepath.Join(filepath.Dir(configPath), "gradient-kubeconfig")
			println(cli.TextSuccess(fmt.Sprintf("KUBECONFIG path: %s", kubeconfigPath)))
			println(cli.TextSuccess(fmt.Sprintf("Cluster %s is up!", cluster.Name)))

			return nil
		},
	}
	command.PersistentFlags().BoolVarP(&reinstall, "reinstall", "r", false, "")
	command.PersistentFlags().BoolVarP(&autoApprove, "auto-approve", "a", false, "")

	return &command
}
