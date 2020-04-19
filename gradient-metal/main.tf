locals {
    has_k8s = var.k8s_endpoint == "" ? false : true
    has_shared_storage = var.shared_storage_path == "" ? false : true
    is_single_node = length(concat(var.k8s_master_ips, var.k8s_workers)) == 1
    label_selector_cpu = local.is_single_node == true ? var.global_selector : "${var.global_selector}-cpu"
    label_selector_gpu = local.is_single_node == true ? var.global_selector : "${var.global_selector}-gpu"
    master_pool_type = local.is_single_node == true ? "gpu" : "cpu"
    service_pool_name = local.is_single_node == true && var.global_selector != "" ? var.global_selector : var.service_pool_name
}

// Kubernetes
module "kubernetes" {
	source          = "./modules/kubernetes"
	enable = !local.has_k8s

	name = var.name
	k8s_version = var.k8s_version
	kubeconfig_path = var.kubeconfig_path
    master_ips = var.k8s_master_ips
    master_pool_type = local.master_pool_type
    service_pool_name = local.service_pool_name
    setup_docker = var.setup_docker
    setup_nvidia = var.setup_nvidia
    ssh_key = var.ssh_key
    ssh_key_path = var.ssh_key_path
    ssh_user = var.ssh_user
    workers = var.k8s_workers
}

/*
# Storage
module "storage" {
	source = "./modules/storage-metal"
	enable = !local.has_shared_storage

	name = var.name
  security_group_ids = local.has_k8s ? split(",", var.k8s_security_group_ids) : [module.network.private_security_group_id]
	subnet_ids = local.has_k8s ? split(",", var.k8s_subnet_ids) : module.network.private_subnet_ids
}
*/

provider "helm" {
    debug = true
    kubernetes {
        host     = module.kubernetes.k8s_host
        username = module.kubernetes.k8s_username

        client_certificate     = module.kubernetes.k8s_client_certificate
        client_key             = module.kubernetes.k8s_client_key
        cluster_ca_certificate = module.kubernetes.k8s_cluster_ca_certificate
        load_config_file = false
    }
}

provider "kubernetes" {
    host     = module.kubernetes.k8s_host
    username = module.kubernetes.k8s_username

    client_certificate     = module.kubernetes.k8s_client_certificate
    client_key             = module.kubernetes.k8s_client_key
    cluster_ca_certificate = module.kubernetes.k8s_cluster_ca_certificate
    load_config_file = false
}

// Gradient
module "gradient_processing" {
	source = "../modules/gradient-processing"
    enabled = module.kubernetes.k8s_host == "" ? false : true

	amqp_hostname = var.amqp_hostname
	amqp_port = var.amqp_port
	amqp_protocol = var.amqp_protocol
	artifacts_access_key_id = var.artifacts_access_key_id
	artifacts_object_storage_endpoint = var.artifacts_object_storage_endpoint
	artifacts_path = var.artifacts_path
	artifacts_secret_access_key = var.artifacts_secret_access_key
	cluster_apikey = var.cluster_apikey
	cluster_handle = var.cluster_handle
	domain = var.domain
    global_selector = var.global_selector
    label_selector_cpu = local.label_selector_cpu
    label_selector_gpu = local.label_selector_gpu
	logs_host = var.logs_host
	gradient_processing_version = var.gradient_processing_version
	name = var.name
	sentry_dsn = var.sentry_dsn
    service_pool_name = local.service_pool_name
    shared_storage_server = var.shared_storage_server
	shared_storage_path = var.shared_storage_path
	shared_storage_type = var.shared_storage_type
	tls_cert = var.tls_cert
	tls_key = var.tls_key
    use_pod_anti_affinity = var.use_pod_anti_affinity
}