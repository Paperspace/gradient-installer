locals {
    has_k8s = var.k8s_endpoint == "" ? false : true
    has_shared_storage = var.shared_storage_path == "" ? false : true
    k8s_version = var.k8s_version == "" ? "1.15.11" : var.k8s_version
    shared_storage_type = var.shared_storage_type == "" ? "nfs" : var.shared_storage_type

    is_single_node = length(var.k8s_workers) == 0
    service_pool_name = local.is_single_node == true && !var.cluster_autoscaler_enabled ? var.k8s_master_node["pool-name"] : var.service_pool_name
}

// Kubernetes
module "kubernetes" {
  source = "../modules/kubernetes"
    enable = !local.has_k8s

    name = var.name

    authentication_sans = var.k8s_sans
    k8s_version = local.k8s_version
    kubeconfig_path = var.kubeconfig_path
    kubelet_extra_binds = []
    master_node = var.k8s_master_node
    reboot_gpu_nodes = var.reboot_gpu_nodes
    service_pool_name = local.service_pool_name
    setup_docker = var.setup_docker
    setup_nvidia = var.setup_nvidia
    ssh_key_private = var.ssh_key == "" ? file(pathexpand(var.ssh_key_path)) : var.ssh_key
    ssh_user = var.ssh_user
    write_kubeconfig = var.write_kubeconfig
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
    version = "1.2.1"
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
    chart = var.gradient_processing_chart
    cluster_apikey = var.cluster_apikey
    cluster_autoscaler_autoscaling_groups = var.cluster_autoscaler_autoscaling_groups
    cluster_autoscaler_cloudprovider = var.cluster_autoscaler_cloudprovider
    cluster_autoscaler_enabled = var.cluster_autoscaler_enabled
    cluster_handle = var.cluster_handle
    domain = var.domain

    helm_repo_username = var.helm_repo_username
    helm_repo_password = var.helm_repo_password
    helm_repo_url = var.helm_repo_url
    elastic_search_host = var.elastic_search_host
    elastic_search_index = var.elastic_search_index
    elastic_search_password = var.elastic_search_password
    elastic_search_port = var.elastic_search_port
    elastic_search_user = var.elastic_search_user

    label_selector_cpu = var.cpu_selector
    label_selector_gpu = var.gpu_selector
    letsencrypt_dns_name = var.letsencrypt_dns_name
    letsencrypt_dns_settings = var.letsencrypt_dns_settings
    // Use shared storage by default for now
    local_storage_server = var.local_storage_server == "" ? var.shared_storage_server : var.local_storage_server
    local_storage_path = var.local_storage_path == "" ? var.shared_storage_path : var.local_storage_path
    local_storage_type = var.local_storage_type == "" ? local.shared_storage_type : var.local_storage_type
    logs_host = var.logs_host
    gradient_processing_version = var.gradient_processing_version
    name = var.name
    sentry_dsn = var.sentry_dsn
    service_pool_name = local.service_pool_name
    shared_storage_server = var.shared_storage_server
    shared_storage_path = var.shared_storage_path
    shared_storage_type = local.shared_storage_type
    tls_cert = var.tls_cert
    tls_key = var.tls_key
    use_pod_anti_affinity = var.use_pod_anti_affinity

  providers = {
    kubernetes = kubernetes
  }
}
