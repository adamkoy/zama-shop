
# ---------- Logging ----------
resource "aws_cloudwatch_log_group" "svc" {
  name              = "/ecs/${var.service_name}"
  retention_in_days = 7
}

# ---------- ECS ----------
resource "aws_ecs_cluster" "this" {
  name = "${var.service_name}-cluster"
}

# Task execution role (pull image from ECR, write logs)
data "aws_iam_policy_document" "ecs_tasks_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task_exec" {
  name               = "${var.service_name}-exec-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json
}

resource "aws_iam_role_policy_attachment" "exec_logs" {
  role       = aws_iam_role.task_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ---------- Service ----------
resource "aws_ecs_service" "svc" {
  name            = "${var.service_name}-svc"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.svc.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  # Allow the app time to come up before failing health checks
  health_check_grace_period_seconds = 60

  network_configuration {
    subnets          = local.subnets
    security_groups  = [aws_security_group.tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.nlb_tg.arn
    container_name   = "prism"
    container_port   = var.container_port
  }


  deployment_circuit_breaker {
    enable   = true # auto rollback on failed deployment
    rollback = true
  }

  # A safe rolling update; tweak to your needs
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  depends_on                         = [aws_lb_listener.tcp_80]
}
