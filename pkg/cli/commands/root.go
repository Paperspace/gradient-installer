package commands

import "github.com/spf13/cobra"

var helpTemplate = `{{ .Short}}

Usage:
  $ {{ .CommandPath }} [COMMAND]

{{- if .HasExample }}

Examples:
	{{.Example}}
{{- end }}

{{- if .HasAvailableSubCommands }}

Commands:
{{- range .Commands -}}
{{- if (or .IsAvailableCommand (eq .Name "help")) }}
  {{ rpad .Name .NamePadding }} {{ .Short }}
{{- end -}}
{{- end -}}
{{- end }}

{{- if .HasAvailableLocalFlags }}

Flags:
{{ .LocalFlags.FlagUsages }}
{{- end }}

{{- if .HasAvailableInheritedFlags }}

Global Flags:
{{ .InheritedFlags.FlagUsages | trimTrailingWhitespaces }}
{{- end }}
`

var versionTemplate = `Gradient Installer/{{ .Version }}
`

var commandName = "gradient-installer"
var version = "latest"

func NewRootCommand(profileName string) *cobra.Command {
	rootCommand := &cobra.Command{
		Use:           commandName,
		Short:         "CLI to manage Paperspace Gradient clusters",
		SilenceErrors: true,
		Version:       version,
	}

	rootCommand.SetHelpTemplate(helpTemplate)
	rootCommand.SetVersionTemplate(versionTemplate)
	rootCommand.AddCommand(NewClusterCommand(version))
	rootCommand.AddCommand(NewSetupCommand(profileName))
	rootCommand.AddCommand(NewUpdateCommand())

	return rootCommand
}
