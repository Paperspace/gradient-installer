
variable "authentication_sans" {
  type        = list
  description = "List of hostname or IPs used for Kubernetes authentications"
}

variable "docker_socket" {
  description = "Path to remote docker socket"
  default     = "/var/run/docker.sock"
}

variable "enable" {
  type        = bool
  description = "If module should be enabled"
}

variable "k8s_version" {
  description = "Kubernetes version"
}

variable "kubeconfig_path" {
  description = "kubeconfig path"
}

variable "kubelet_extra_binds" {
  type        = list
  description = "Kubelet extra binds"
}

variable "master_node" {
  type        = map
  description = "Kubernetes master node"
}

variable "name" {
  description = "Name"
}

variable "reboot_gpu_nodes" {
  type        = bool
  description = "Reboot GPU nodes"
}

variable "setup_docker" {
  description = "Setup docker"
}
variable "setup_nvidia" {
  description = "Setup NVIDIA drivers and nvidia-docker"
}

variable "service_pool_name" {
  description = "Service pool selector"
}

variable "ssh_key_private" {
  description = "Private SSH key"
}

variable "ssh_user" {
  description = "SSH user"
}

variable "workers" {
  type        = list
  description = "Kubernetes workers"
}

variable "write_kubeconfig" {
  description = "Write kubeconfig to a file"
}