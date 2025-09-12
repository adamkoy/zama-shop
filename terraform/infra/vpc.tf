
data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.service_name
  cidr = var.vpc_cidr

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnets  = var.public_subnet_cidrs
  private_subnets = var.private_subnet_cidrs

  enable_dns_hostnames = true
  enable_dns_support   = true

  # NAT only when using private subnets for ECS tasks
  enable_nat_gateway = var.use_private_subnets
  single_nat_gateway = var.use_private_subnets
}

# Choose ECS subnets + public IP behavior based on the flag
locals {
  ecs_subnets      = var.use_private_subnets ? module.vpc.private_subnets : module.vpc.public_subnets
  assign_public_ip = var.use_private_subnets ? false : true
}