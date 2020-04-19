locals {
    asg_max_size_default = 600
    #cpu_ami_id = "ami-055047a9bc93fd2bf"
    #gpu_ami_id = "ami-0ca7c6c8dd5aced03"
    cpu_ami_id = "ami-0bf3e2c598f50ba82"
    gpu_ami_id = "ami-031814549a4b2892c"
    root_volume_size_default = 50

    node_ami_ids = {
        "services-small"=local.cpu_ami_id,
        "services-medium"=local.cpu_ami_id,
        "services-large"=local.cpu_ami_id,

        "experiment-cpu-small"=local.cpu_ami_id,
        "experiment-cpu-medium"=local.cpu_ami_id,
        "experiment-gpu-small"=local.gpu_ami_id,
        "experiment-gpu-medium"=local.gpu_ami_id,
        "experiment-gpu-large"=local.gpu_ami_id,

        "model-deployment-cpu-small"=local.cpu_ami_id,
        "model-deployment-cpu-medium"=local.cpu_ami_id,
        "model-deployment-gpu-small"=local.gpu_ami_id,
        "model-deployment-gpu-medium"=local.gpu_ami_id,
        "model-deployment-gpu-large"=local.gpu_ami_id,

        "notebook-cpu-small"=local.cpu_ami_id,
        "notebook-cpu-medium"=local.cpu_ami_id,
        "notebook-gpu-small"=local.gpu_ami_id,
        "notebook-gpu-medium"=local.gpu_ami_id,
        "notebook-gpu-large"=local.gpu_ami_id,

        "tensorboard-cpu-small"=local.cpu_ami_id,
        "tensorboard-cpu-medium"=local.cpu_ami_id,
        "tensorboard-gpu-small"=local.gpu_ami_id,
        "tensorboard-gpu-medium"=local.gpu_ami_id,
        "tensorboard-gpu-large"=local.gpu_ami_id,
    }

    node_instance_types = merge({
        "services-small"="c5.xlarge",
        "services-medium"="c5.xlarge",
        "services-large"="c5.2xlarge",

        "experiment-cpu-small"="c5.xlarge",
        "experiment-cpu-medium"="c5.4xlarge",
        "experiment-gpu-small"="p3.2xlarge",
        "experiment-gpu-medium"="p3.2xlarge",
        "experiment-gpu-large"="p3.16xlarge",

        "model-deployment-cpu-small"="c5.xlarge",
        "model-deployment-cpu-medium"="c5.4xlarge",
        "model-deployment-gpu-small"="p3.2xlarge",
        "model-deployment-gpu-medium"="p3.2xlarge",
        "model-deployment-gpu-large"="p3.16xlarge",

        "notebook-cpu-small"="c5.xlarge",
        "notebook-cpu-medium"="c5.4xlarge",
        "notebook-gpu-small"="p3.2xlarge",
        "notebook-gpu-medium"="p3.2xlarge",
        "notebook-gpu-large"="p3.16xlarge",

        "tensorboard-cpu-small"="c5.xlarge",
        "tensorboard-cpu-medium"="c5.4xlarge",
        "tensorboard-gpu-small"="p3.2xlarge",
        "tensorboard-gpu-medium"="p3.2xlarge",
        "tensorboard-gpu-large"="p3.16xlarge",
    }, var.node_instance_types)

    node_asg_desired_sizes = {
        "services-small"=0,
        "services-medium"=0,
        "services-large"=0,

        "experiment-cpu-small"=0,
        "experiment-cpu-medium"=0,
        "experiment-gpu-small"=0,
        "experiment-gpu-medium"=0,
        "experiment-gpu-large"=0

        "model-deployment-cpu-small"=0,
        "model-deployment-cpu-medium"=0,
        "model-deployment-gpu-small"=0,
        "model-deployment-gpu-medium"=0,
        "model-deployment-gpu-large"=0

        "notebook-cpu-small"=0,
        "notebook-cpu-medium"=0,
        "notebook-gpu-small"=0,
        "notebook-gpu-medium"=0,
        "notebook-gpu-large"=0,

        "tensorboard-cpu-small"=0,
        "tensorboard-cpu-medium"=0,
        "tensorboard-gpu-small"=0,
        "tensorboard-gpu-medium"=0,
        "tensorboard-gpu-large"=0,
    }

    node_asg_min_sizes = merge({
        "services-small"=1,
        "services-medium"=0,
        "services-large"=0,

        "experiment-cpu-small"=1,
        "experiment-cpu-medium"=0,
        "experiment-gpu-small"=0,
        "experiment-gpu-medium"=0,
        "experiment-gpu-large"=0

        "model-deployment-cpu-small"=1,
        "model-deployment-cpu-medium"=0,
        "model-deployment-gpu-small"=0,
        "model-deployment-gpu-medium"=0,
        "model-deployment-gpu-large"=0

        "notebook-cpu-small"=1,
        "notebook-cpu-medium"=0,
        "notebook-gpu-small"=0,
        "notebook-gpu-medium"=0,
        "notebook-gpu-large"=0,

        "tensorboard-cpu-small"=1,
        "tensorboard-cpu-medium"=0,
        "tensorboard-gpu-small"=0,
        "tensorboard-gpu-medium"=0,
        "tensorboard-gpu-large"=0,
    }, var.node_asg_min_sizes)

    node_asg_max_sizes = merge({
        "services-small"=local.asg_max_size_default,
        "services-medium"=local.asg_max_size_default,
        "services-large"=local.asg_max_size_default,

        "experiment-cpu-small"=local.asg_max_size_default,
        "experiment-cpu-medium"=local.asg_max_size_default,
        "experiment-gpu-small"=local.asg_max_size_default,
        "experiment-gpu-medium"=local.asg_max_size_default,
        "experiment-gpu-large"=local.asg_max_size_default,

        "model-deployment-cpu-small"=local.asg_max_size_default,
        "model-deployment-cpu-medium"=local.asg_max_size_default,
        "model-deployment-gpu-small"=local.asg_max_size_default,
        "model-deployment-gpu-medium"=local.asg_max_size_default,
        "model-deployment-gpu-large"=local.asg_max_size_default,

        "notebook-cpu-small"=local.asg_max_size_default,
        "notebook-cpu-medium"=local.asg_max_size_default,
        "notebook-gpu-small"=local.asg_max_size_default,
        "notebook-gpu-medium"=local.asg_max_size_default,
        "notebook-gpu-large"=local.asg_max_size_default,

        "tensorboard-cpu-small"=local.asg_max_size_default,
        "tensorboard-cpu-medium"=local.asg_max_size_default,
        "tensorboard-gpu-small"=local.asg_max_size_default,
        "tensorboard-gpu-medium"=local.asg_max_size_default,
        "tensorboard-gpu-large"=local.asg_max_size_default,
    }, var.node_asg_max_sizes)

    node_types = [
        "services-small",
        "services-medium",
        "services-large",

        "experiment-cpu-small",
        "experiment-cpu-medium",
        "experiment-gpu-small",
        "experiment-gpu-medium",
        "experiment-gpu-large",

        "model-deployment-cpu-small",
        "model-deployment-cpu-medium",
        "model-deployment-gpu-small",
        "model-deployment-gpu-medium",
        "model-deployment-gpu-large",

        "notebook-cpu-small",
        "notebook-cpu-medium",
        "notebook-gpu-small",
        "notebook-gpu-medium",
        "notebook-gpu-large",

        "tensorboard-cpu-small",
        "tensorboard-cpu-medium",
        "tensorboard-gpu-small",
        "tensorboard-gpu-medium",
        "tensorboard-gpu-large",
    ]

    node_volume_sizes = merge({
        "services-small"=local.root_volume_size_default,
        "services-medium"=local.root_volume_size_default,
        "services-large"=local.root_volume_size_default,

        "experiment-cpu-small"=local.root_volume_size_default,
        "experiment-cpu-medium"=local.root_volume_size_default,
        "experiment-gpu-small"=local.root_volume_size_default,
        "experiment-gpu-medium"=local.root_volume_size_default,
        "experiment-gpu-large"=local.root_volume_size_default,

        "model-deployment-cpu-small"=local.root_volume_size_default,
        "model-deployment-cpu-medium"=local.root_volume_size_default,
        "model-deployment-gpu-small"=local.root_volume_size_default,
        "model-deployment-gpu-medium"=local.root_volume_size_default,
        "model-deployment-gpu-large"=local.root_volume_size_default,

        "notebook-cpu-small"=local.root_volume_size_default,
        "notebook-cpu-medium"=local.root_volume_size_default,
        "notebook-gpu-small"=local.root_volume_size_default,
        "notebook-gpu-medium"=local.root_volume_size_default,
        "notebook-gpu-large"=local.root_volume_size_default,

        "tensorboard-cpu-small"=local.root_volume_size_default,
        "tensorboard-cpu-medium"=local.root_volume_size_default,
        "tensorboard-gpu-small"=local.root_volume_size_default,
        "tensorboard-gpu-medium"=local.root_volume_size_default,
        "tensorboard-gpu-large"=local.root_volume_size_default,
    }, var.node_asg_max_sizes)

    worker_groups = [for node_type in local.node_types : {
        name = node_type
        additional_security_group_ids = var.node_security_group_ids
        ami_id = local.node_ami_ids[node_type]
        asg_force_delete = true
        asg_desired_capacity = local.node_asg_desired_sizes[node_type]
        asg_max_size = local.node_asg_max_sizes[node_type]
        asg_min_size = local.node_asg_min_sizes[node_type]
        instance_type = local.node_instance_types[node_type]
        key_name = var.public_key == "" ? "" : aws_key_pair.main[0].id
        kubelet_extra_args = "--node-labels=paperspace.com/pool-name=${node_type},paperspace.com/pool-type=${split("-", node_type)[1]},node-role.kubernetes.io/node=,node-role.kubernetes.io/worker=,node-role.kubernetes.io/${node_type}"

        tags = [
            {
                key                 = "k8s.io/cluster-autoscaler/${var.name}",
                value               = "true",
                propagate_at_launch = 1,
            },
            {
                key                 = "k8s.io/cluster-autoscaler/enabled",
                value               = "true",
                propagate_at_launch = 1,
            },
            {
                key = "k8s.io/cluster-autoscaler/node-template/label/paperspace.com/pool-name"
                value = node_type
                propagate_at_launch = 1,
            }
        ]
    }]
}

data "aws_eks_cluster" "cluster" {
    count = var.enable ? 1 : 0
    name  = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
    count = var.enable ? 1 : 0
    name  = module.eks.cluster_id
}

provider "kubernetes" {
    host                   = element(concat(data.aws_eks_cluster.cluster[*].endpoint, list("")), 0)
    cluster_ca_certificate = base64decode(element(concat(data.aws_eks_cluster.cluster[*].certificate_authority.0.data, list("")), 0))
    token                  = element(concat(data.aws_eks_cluster_auth.cluster[*].token, list("")), 0)
    load_config_file       = false
    version = "1.11.1"
}

resource "aws_key_pair" "main" {
    count = var.public_key == "" ? 0 : 1
    key_name   = var.name
    public_key = var.public_key
}

module "eks" {
    source          = "terraform-aws-modules/eks/aws"

    config_output_path = pathexpand(var.kubeconfig_path)
    create_eks = var.enable
    cluster_name    = var.name
    cluster_version = var.k8s_version
    map_accounts = var.iam_accounts
    map_roles = var.iam_roles
    map_users = var.iam_users
    subnets         = var.node_subnet_ids
    vpc_id          = var.vpc_id

    wait_for_cluster_cmd = "until curl -k -s $ENDPOINT/healthz >/dev/null; do sleep 4; done"
    worker_groups = local.worker_groups
}

resource "null_resource" "cluster_status" {
  depends_on = [module.eks]

  provisioner "local-exec" {
    command     = "until curl -k -s $ENDPOINT/healthz >/dev/null; do sleep 4; done"
    environment = {
      ENDPOINT = element(concat(data.aws_eks_cluster.cluster[*].endpoint, list("")), 0)
    }
  }
}