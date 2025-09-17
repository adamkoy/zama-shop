output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "private_subnets" {
  value = module.vpc.private_subnets
}
output "alb_dns_name" {
  value       = aws_lb.nlb.dns_name
  description = "ALB DNS name"
}

output "alb_url" {
  value       = "http://${aws_lb.nlb.dns_name}"
  description = "Convenience HTTP URL for curl"
}

output "service_name" {
  value       = var.service_name
  description = "Service name used for log groups"
}

output "api_base_url" {
  value       = "https://${aws_api_gateway_rest_api.api.id}.execute-api.${var.region}.amazonaws.com/${aws_api_gateway_stage.prod.stage_name}/"
  description = "API Gateway base URL"
}

output "api_key_value_effective" {
  value     = local.api_key_final
  sensitive = true
}

data "aws_region" "current" {}