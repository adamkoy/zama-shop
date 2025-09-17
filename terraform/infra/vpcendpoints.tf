# --- SG for Interface Endpoints (allow 443 from private subnets)
resource "aws_security_group" "vpce" {
  name   = "${var.service_name}-vpce-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = module.vpc.private_subnets_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# # --- ECR API endpoint
# resource "aws_vpc_endpoint" "ecr_api" {
#   vpc_id              = module.vpc.vpc_id
#   vpc_endpoint_type   = "Interface"
#   service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
#   subnet_ids          = module.vpc.private_subnets
#   security_group_ids  = [aws_security_group.vpce.id]
#   private_dns_enabled = true
# }

# # --- ECR DKR endpoint (image registry)
# resource "aws_vpc_endpoint" "ecr_dkr" {
#   vpc_id              = module.vpc.vpc_id
#   vpc_endpoint_type   = "Interface"
#   service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
#   subnet_ids          = module.vpc.private_subnets
#   security_group_ids  = [aws_security_group.vpce.id]
#   private_dns_enabled = true
# }

# --- CloudWatch Logs (so tasks can log without NAT)
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = module.vpc.vpc_id
  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.${data.aws_region.current.name}.logs"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpce.id]
  private_dns_enabled = true
}
