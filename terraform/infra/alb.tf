# --- Internal NLB (L4) ---
resource "aws_lb" "nlb" {
  name               = "${var.service_name}-nlb"
  load_balancer_type = "network"
  internal           = true
  subnets            = module.vpc.private_subnets
}

# --- NLB Target Group (TCP) ---
resource "aws_lb_target_group" "nlb_tg" {
  name        = "${var.service_name}-nlb-tg"
  port        = var.container_port
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = module.vpc.vpc_id

  # Keep HC at L4 for NLB
  health_check {
    protocol = "TCP"
    port     = "traffic-port"
  }
}

# --- NLB Listener ---
resource "aws_lb_listener" "tcp_80" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_tg.arn
  }
}