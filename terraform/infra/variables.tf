############################
# Account / Env
############################
variable "region" {
  description = "AWS region for all resources."
  type        = string
  default     = "eu-west-3"
}

variable "account_id" {
  description = "AWS account ID."
  type        = string
  default     = "717916807684"
}

variable "service_name" {
  description = "Logical service/app name used for resource names and tags."
  type        = string
  default     = "zama-shop"
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)."
  type        = string
  default     = "dev"
}

############################
# VPC (if you create a new one)
############################
variable "vpc_cidr" {
  description = "CIDR for the new VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDRs for public subnets."
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDRs for private subnets (for ECS tasks)."
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "use_private_subnets" {
  description = "Place ECS tasks in private subnets behind NAT (recommended)."
  type        = bool
  default     = false
}

############################
# ECS / Image
############################
variable "ecs_container_name" {
  description = "Primary container name in the ECS task definition."
  type        = string
  default     = "app"
}

variable "container_port" {
  description = "Container port exposed by your service (Prism mock uses 4010)."
  type        = number
  default     = 4010
}

variable "image_uri" {
  description = "ECR image URI (must match account_id and region)."
  type        = string
  # NOTE: region aligned with eu-west-3
  default = "717916807684.dkr.ecr.eu-west-3.amazonaws.com/zama-shop:latest"
}

############################
# API Gateway / Security
############################
variable "ssm_api_key_name" {
  description = "SSM parameter (SecureString) name that stores the API key value."
  type        = string
  default     = "/zama-shop/api_key"
}

variable "waf_rate_limit" {
  description = "Max requests per 5 minutes per IP before WAF blocks."
  type        = number
  default     = 5000
}


############################
# POC Quiet Mode (APIGW deploy churn control)
############################
variable "poc_quiet" {
  description = "Silence API Gateway deployment churn during POC."
  type        = bool
  default     = true
}

variable "apigw_redeploy_seed" {
  description = "Bump this string when you WANT a redeploy (even in quiet mode)."
  type        = string
  default     = ""
}

############################
# Tags
############################
variable "tags" {
  description = "Common tags applied to supported resources."
  type        = map(string)
  default = {
    Project     = "zama-shop"
    ManagedBy   = "terraform"
    Environment = "dev"
  }
}