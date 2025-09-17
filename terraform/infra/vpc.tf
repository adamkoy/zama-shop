
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
  enable_nat_gateway = true
  single_nat_gateway = true
}

# Choose ECS subnets + public IP behavior based on the flag
locals {
  subnets          = module.vpc.private_subnets 
  assign_public_ip =  false
  vpc_cidr_block   = var.vpc_cidr
}
