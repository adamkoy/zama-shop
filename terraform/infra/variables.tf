
# Account variables
variable "region" {
  type    = string
  default = "eu-west-3"
}

variable "account_id" {
  type    = string
  default = "717916807684"
}


variable "service_name" {
  type    = string
  default = "zama-shop"
}


# --- VPC module inputs ---
variable "vpc_cidr" {
  description = "CIDR for the new VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDRs for public subnets"
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDRs for private subnets (used when use_private_subnets = true)"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "use_private_subnets" {
  description = "Place ECS tasks in private subnets (creates NAT). If false, use public subnets with public IPs."
  type        = bool
  default     = false
}

# --- ECS inputs ---
variable "container_port" {
  type        = number
  default     = 4010
  description = "Container port exposed by the Prism mock server."
}

variable "image_uri" {
  type        = string
  description = "ECR image URI for the Prism image"
  default     = "717916807684.dkr.ecr.eu-west-1.amazonaws.com/zama-shop:latest"
}
variable "ssm_api_key_name" {
  description = "SSM parameter name for the API key"
  type        = string
  default     = "/zama/api_key"
}