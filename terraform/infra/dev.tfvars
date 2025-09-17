# ------- Account / Env -------
region       = "eu-west-3"
account_id   = "717916807684"
service_name = "zama-shop"
environment  = "dev"

# ------- VPC -------
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.0.0/24", "10.0.1.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]

# Toggle: private ECS/ALB (recommended w/ API Gateway VPC Link) or public
use_private_subnets = false

# ------- ECS / Image -------
ecs_container_name = "app"
container_port     = 4010
image_uri          = "717916807684.dkr.ecr.eu-west-3.amazonaws.com/zama-shop:latest"

# ------- API Gateway / Security -------
ssm_api_key_name = "/zama/api_key"
waf_rate_limit   = 10

# ------- APIGW -------
apigw_redeploy_seed = ""

# ------- Tags -------
tags = {
  Project     = "zama-shop"
  ManagedBy   = "terraform"
  Environment = "dev"
}

# ------- Alerts -------
sns_topic_arn = null
alert_email   = "example@mail.com"
