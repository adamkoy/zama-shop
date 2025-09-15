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
  value       = aws_lb.this.dns_name
  description = "ALB DNS name"
}

output "alb_url" {
  value       = "http://${aws_lb.this.dns_name}"
  description = "Convenience HTTP URL for curl"
}

output "service_name" {
  value       = var.service_name
  description = "Service name used for log groups"
}
