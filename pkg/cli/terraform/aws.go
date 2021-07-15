package terraform

import "fmt"

type AWS struct {
	*Common
}

func NewAWS(version string) *AWS {
	aws := AWS{
		Common: NewCommon(),
	}

	refVersion := "master"
	if version != "latest" && version != "" {
		refVersion = version
	}
	aws.TerraformSource = fmt.Sprintf("%s?ref=%s/gradient-aws", SourcePrefix, refVersion)
	return &aws
}
