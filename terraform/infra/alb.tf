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
  protocol    = "TCP" # data traffic stays TCP
  target_type = "ip"
  vpc_id      = module.vpc.vpc_id

  health_check {
    protocol            = "HTTP"
    port                = "traffic-port" # or var.container_port
    path                = "/healthz"
    matcher             = "200-399"
    interval            = 15
    timeout             = 6
    healthy_threshold   = 2
    unhealthy_threshold = 3
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
