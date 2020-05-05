global:
  amqpExchange: ${cluster_handle}
  artifactsPath: ${artifacts_path}
  artifactsAccessKeyId: ${artifacts_access_key_id}
  artifactsSecretAccessKey: ${artifacts_secret_access_key}
  cluster:
    handle: ${cluster_handle}
    name: ${name}
  %{ if elastic_search_password != "" }
  elasticSearch:
    host: ${elastic_search_host}
    index: ${elastic_search_index}
    password: ${elastic_search_password}
    port: ${elastic_search_port}
    user: ${elastic_search_user}
  %{ endif }
  logsHost: ${logs_host}
  ingressHost: ${domain}
  serviceNodeSelector:
    paperspace.com/pool-name: ${service_pool_name}

  defaultStorageName: ${default_storage_name}
  sharedStorageName: ${shared_storage_name}
  storage:
    gradient-processing-local:
      class: gradient-processing-local
      path: ${local_storage_path}
      server: ${local_storage_server}
      type: ${local_storage_type}
    gradient-processing-shared:
      class: gradient-processing-shared
      path: ${shared_storage_path}
      server: ${shared_storage_server}
      type: ${shared_storage_type}

secrets: 
  amqpUri: ${amqp_uri}
  clusterApikey: ${cluster_apikey}
  tlsCert: "${tls_cert}"
  tlsKey: "${tls_key}"
  traefikPrometheusAuth: ${traefik_prometheus_auth}

cluster-autoscaler:
  enabled: ${cluster_autoscaler_enabled}

  awsRegion: ${aws_region}
  autoDiscovery:
    clusterName: ${name}
  nodeSelector:
    paperspace.com/pool-name: ${service_pool_name}

efs-provisioner:
  enabled: ${efs_provisioner_enabled}
  efsProvisioner:
    awsRegion: ${aws_region}
    efsFileSystemId: ${split(".", shared_storage_server)[0]}
    path: ${shared_storage_path}
  nodeSelector:
    paperspace.com/pool-name: ${service_pool_name}

fluent-bit:
  rawConfig: |-
    # used to trigger changes
    elasticSearch:
        host: ${elastic_search_host}
        password: ${elastic_search_password}
        port: ${elastic_search_port}
        user: ${elastic_search_user}

gradient-operator:
  config:
    ingressHost: ${domain}
    usePodAntiAffinity: ${use_pod_anti_affinity}
    %{ if global_selector != "" }
    modelDeploymentConfig:
      labelName: paperspace.com/pool-name
      cpu:
        small:
          label: ${label_selector_cpu}
        medium:
          label: ${label_selector_cpu}
        large:
          label: ${label_selector_cpu}
      gpu:
        small:
          label: ${label_selector_gpu}
          requests:
            memory: 5Gi
        medium:
          label: ${label_selector_gpu}
          requests:
            memory: 20Gi
        large:
          label: ${label_selector_gpu}
          requests:
            memory: 58Gi

    experimentConfig:
      labelName: paperspace.com/pool-name
      cpu:
        small:
          label: ${label_selector_cpu}
        medium:
          label: ${label_selector_cpu}
        large:
          label: ${label_selector_cpu}
      gpu:
        small:
          label: ${label_selector_gpu}
          requests:
            memory: 5Gi
        medium:
          label: ${label_selector_gpu}
          requests:
            memory: 20Gi
        large:
          label: ${label_selector_gpu}
          requests:
            memory: 58Gi
    notebookConfig:
      labelName: paperspace.com/pool-name
      cpu:
        small:
          label: ${label_selector_cpu}
        medium:
          label: ${label_selector_cpu}
        large:
          label: ${label_selector_cpu}
      gpu:
        small:
          label: ${label_selector_gpu}
          requests:
            memory: 5Gi
        medium:
          label: ${label_selector_gpu}
          requests:
            memory: 20Gi
        large:
          label: ${label_selector_gpu}
          requests:
            memory: 58Gi
    tensorboardConfig:
      labelName: paperspace.com/pool-name
      cpu:
        small:
          label: ${label_selector_cpu}
        medium:
          label: ${label_selector_cpu}
        large:
          label: ${label_selector_cpu}
      gpu:
        small:
          label: ${label_selector_gpu}
          requests:
            memory: 5Gi
        medium:
          label: ${label_selector_gpu}
          requests:
            memory: 20Gi
        large:
          label: ${label_selector_gpu}
          requests:
            memory: 58Gi
    %{ endif }

gradient-metrics:
  ingress:
    hostPath:
      ${domain}: /metrics
    tls:
      - secretName: ${tls_secret_name}
        hosts:
          - ${domain}

gradient-operator-dispatcher:
  config:
    sentryEnvironment: ${name}
    sentryDSN: ${sentry_dsn}

nfs-client-provisioner:
  enabled: ${nfs_client_provisioner_enabled}
  nfs:
    path: ${shared_storage_path}
    server: ${shared_storage_server}
  nodeSelector:
    paperspace.com/pool-name: ${service_pool_name}

prometheus:
  nodeSelector:
    paperspace.com/pool-name: ${service_pool_name}
  server:
    enabled: ${traefik_prometheus_auth_enabled}
    ingress:
      hosts:
        - ${domain}
  kubeStateMetrics:
    nodeSelector:
      paperspace.com/pool-name: ${service_pool_name}

prom-aggregation-gateway:
  ingress:
    hostPath:
      ${domain}: /gateway
    tls:
    - secretName: ${tls_secret_name}
      hosts:
      - ${domain}

traefik:
  replicas: 1
  nodeSelector:
    paperspace.com/pool-name: ${service_pool_name}
  %{ if global_selector != "" }
  serviceType: NodePort
  deployment:
    hostNetwork: true
    hostPort:
      httpEnabled: true
      httpPort: 80
      httpsEnabled: true
      httpsPort: 443
  %{ endif }