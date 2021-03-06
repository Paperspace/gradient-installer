locals {
  helm_repo_url       = var.helm_repo_url == "" ? "https://infrastructure-public-chart-museum-repository.storage.googleapis.com" : var.helm_repo_url
  letsencrypt_enabled = (length(var.letsencrypt_dns_settings) != 0 && (var.tls_cert == "" && var.tls_key == ""))

  local_storage_config = var.local_storage_config == "" ? {} : jsondecode(var.local_storage_config)
  local_storage_name   = "gradient-processing-local"
  local_storage_secrets = {
    "ceph-csi-fs" = {
      "global.storage.gradient-processing-local.user"     = lookup(local.local_storage_config, "user", "")
      "global.storage.gradient-processing-local.password" = lookup(local.local_storage_config, "password", "")
    }
  }
  shared_storage_config = var.shared_storage_config == "" ? {} : jsondecode(var.shared_storage_config)
  shared_storage_name   = "gradient-processing-shared"
  shared_storage_secrets = {
    "ceph-csi-fs" = {
      "global.storage.gradient-processing-shared.user"     = lookup(local.shared_storage_config, "user", "")
      "global.storage.gradient-processing-shared.password" = lookup(local.shared_storage_config, "password", "")
    }
  }

  tls_secret_name      = "gradient-processing-tls"
  prometheus_pool_name = var.prometheus_pool_name != "" ? var.prometheus_pool_name : var.service_pool_name
}

resource "helm_release" "cert_manager" {
  count = var.cert_manager_enabled ? 1 : 0

  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.cert_manager_version

  values = [
    yamlencode({
      "installCRDs" = true
      "nodeSelector" = {
        "paperspace.com/pool-name" = var.service_pool_name
      }
    })
  ]
}

resource "helm_release" "gradient_processing" {
  name                = "gradient-processing"
  repository          = local.helm_repo_url
  repository_username = var.helm_repo_username
  repository_password = var.helm_repo_password
  chart               = var.chart
  version             = var.gradient_processing_version

  set_sensitive {
    name  = "global.elasticSearch.password"
    value = var.elastic_search_password
  }
  set_sensitive {
    name  = "global.artifactsAccessKeyId"
    value = var.artifacts_access_key_id
  }
  set_sensitive {
    name  = "global.artifactsSecretAccessKey"
    value = var.artifacts_secret_access_key
  }
  set_sensitive {
    name  = "secrets.amqpUri"
    value = "${var.amqp_protocol}://${var.cluster_handle}:${var.cluster_apikey}@${var.amqp_hostname}/"
  }
  set_sensitive {
    name  = "secrets.clusterApikey"
    value = var.cluster_apikey
  }
  set_sensitive {
    name  = "secrets.clusterAuthorizationToken"
    value = var.cluster_authorization_token
  }
  set_sensitive {
    name  = "secrets.tlsCert"
    value = var.tls_cert
  }
  set_sensitive {
    name  = "secrets.tlsKey"
    value = var.tls_key
  }

  set_sensitive {
    name  = "traefik.acme.dnsProvider.name"
    value = var.letsencrypt_dns_name
  }
  set_sensitive {
    name  = "traefik.ssl.defaultCert"
    value = var.tls_cert == "" ? "null" : base64encode(var.tls_cert)
  }
  set_sensitive {
    name  = "traefik.ssl.defaultKey"
    value = var.tls_key == "" ? "null" : base64encode(var.tls_key)
  }
  set_sensitive {
    name  = "gradient-metrics.config.newRelicKey"
    value = var.metrics_new_relic_key
  }

  dynamic "set_sensitive" {
    for_each = lookup(local.local_storage_secrets, var.local_storage_type, {})
    content {
      name  = "secrets.${set_sensitive.key}"
      value = set_sensitive.value
    }
  }

  dynamic "set_sensitive" {
    for_each = lookup(local.shared_storage_secrets, var.shared_storage_type, {})
    content {
      name  = "secrets.${set_sensitive.key}"
      value = set_sensitive.value
    }
  }


  dynamic "set_sensitive" {
    for_each = var.letsencrypt_dns_settings

    content {
      name  = "traefik.acme.dnsProvider.${var.letsencrypt_dns_name}.${set_sensitive.key}"
      value = set_sensitive.value
    }
  }

  values = [
    templatefile("${path.module}/templates/values.yaml.tpl", {
      enabled = var.enabled

      aws_region                            = var.aws_region
      artifacts_path                        = var.artifacts_path
      cluster_autoscaler_autoscaling_groups = var.cluster_autoscaler_autoscaling_groups
      cluster_autoscaler_cloudprovider      = var.cluster_autoscaler_cloudprovider
      cluster_autoscaler_enabled            = var.cluster_autoscaler_enabled
      cluster_autoscaler_delay_after_add    = var.cluster_autoscaler_delay_after_add
      cluster_autoscaler_unneeded_time      = var.cluster_autoscaler_unneeded_time
      cluster_handle                        = var.cluster_handle
      cluster_secret_checksum               = sha256("${var.cluster_handle}${var.cluster_apikey}")
      default_storage_name                  = local.local_storage_name
      efs_provisioner_enabled               = var.shared_storage_type == "efs" || var.local_storage_type == "efs"
      elastic_search_enabled                = var.elastic_search_password != ""
      elastic_search_host                   = var.elastic_search_host
      elastic_search_index                  = var.elastic_search_index
      elastic_search_port                   = var.elastic_search_port
      elastic_search_sha                    = sha256("${var.elastic_search_host}${var.elastic_search_password}${var.elastic_search_port}${var.elastic_search_user}")
      elastic_search_user                   = var.elastic_search_user
      is_public_cluster                     = var.is_public_cluster
      domain                                = var.domain
      global_selector                       = var.global_selector
      label_selector_cpu                    = var.label_selector_cpu
      label_selector_gpu                    = var.label_selector_gpu
      lb_count                              = var.lb_count
      lb_pool_name                          = var.lb_pool_name
      letsencrypt_enabled                   = local.letsencrypt_enabled
      local_storage_config                  = local.local_storage_config
      local_storage_name                    = local.local_storage_name
      local_storage_path                    = var.local_storage_path
      local_storage_server                  = var.local_storage_server
      local_storage_type                    = var.local_storage_type
      logs_host                             = var.logs_host
      name                                  = var.name
      nfs_client_provisioner_enabled        = var.shared_storage_type == "nfs" || var.local_storage_type == "nfs"
      paperspace_base_url                   = var.paperspace_base_url
      sentry_dsn                            = var.sentry_dsn
      service_pool_name                     = var.service_pool_name
      shared_storage_config                 = local.shared_storage_config
      shared_storage_name                   = local.shared_storage_name
      shared_storage_path                   = var.shared_storage_path
      shared_storage_server                 = var.shared_storage_server
      shared_storage_type                   = var.shared_storage_type
      tls_secret_name                       = local.tls_secret_name
      use_pod_anti_affinity                 = var.use_pod_anti_affinity
      metrics_new_relic_enabled             = var.metrics_new_relic_enabled
      metrics_new_relic_name                = var.metrics_new_relic_name
      pod_assignment_label_name             = var.pod_assignment_label_name
      legacy_datasets_host_path             = var.legacy_datasets_host_path
      legacy_datasets_sub_path              = var.legacy_datasets_sub_path
      legacy_datasets_pvc_name              = var.legacy_datasets_pvc_name
      anti_crypto_miner_regex               = var.anti_crypto_miner_regex
      prometheus_resources                  = var.prometheus_resources
      prometheus_pool_name                  = local.prometheus_pool_name
      image_cache_enabled                   = var.image_cache_enabled
      image_cache_list                      = jsonencode(var.image_cache_list)
    })
  ]
}

data "kubernetes_service" "traefik" {
  metadata {
    // Needed to use replace to overcome constant refresh caused by depends_on
    name = "traefik${replace(helm_release.gradient_processing.metadata[0].revision, "/.*/", "")}"
  }
}
