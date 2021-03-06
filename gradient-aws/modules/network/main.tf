locals {
    az_count = length(var.availability_zones)
    cidr_netmask = split("/", var.cidr)[1]
    netmask_unit = var.subnet_netmask - local.cidr_netmask
    private_cidr_blocks = [for count in range(local.az_count): cidrsubnet(var.cidr, local.netmask_unit, count)]
    public_cidr_blocks = [for count in range(local.az_count): cidrsubnet(var.cidr, local.netmask_unit, local.az_count + count)]
}

resource "aws_eip" "nat" {
  count = 1
  vpc = true
}

module "vpc" {
    source = "terraform-aws-modules/vpc/aws"

    name = var.name
    create_vpc = var.enable

    azs = var.availability_zones
    cidr = var.cidr
    enable_dns_hostnames = true
    enable_nat_gateway = true
    external_nat_ip_ids = aws_eip.nat.*.id
    private_subnet_tags = var.private_subnet_tags
    private_subnets = local.private_cidr_blocks
    public_subnet_tags = var.public_subnet_tags
    public_subnets = local.public_cidr_blocks
    reuse_nat_ips = true
    single_nat_gateway = true
    vpc_tags = var.vpc_tags
}