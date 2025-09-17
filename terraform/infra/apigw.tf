############################
# API Gateway (REST) + Key #
############################


resource "aws_api_gateway_vpc_link" "link" {
  name        = "${var.service_name}-vpc-link"
  target_arns = [aws_lb.nlb.arn]
}

resource "aws_cloudwatch_log_group" "apigw_access" {
  name              = "/apigw/${var.service_name}/access"
  retention_in_days = 7
}

resource "aws_api_gateway_rest_api" "api" {
  name  = "${var.service_name}-gw"
}

# /healthz (open)
resource "aws_api_gateway_resource" "healthz" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "healthz"
}

resource "aws_api_gateway_method" "healthz_get" {
  rest_api_id      = aws_api_gateway_rest_api.api.id
  resource_id      = aws_api_gateway_resource.healthz.id
  http_method      = "GET"
  authorization    = "NONE"
  api_key_required = false
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy_any" {
  rest_api_id      = aws_api_gateway_rest_api.api.id
  resource_id      = aws_api_gateway_resource.proxy.id
  http_method      = "ANY"
  authorization    = "NONE"
  api_key_required = true

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "healthz_proxy" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.healthz.id
  http_method             = aws_api_gateway_method.healthz_get.http_method

  type                    = "HTTP_PROXY"
  integration_http_method = "GET"

  # private connectivity
  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.link.id

  # NLB DNS (internal)
  uri                     = "http://${aws_lb.nlb.dns_name}/healthz"
}

resource "aws_api_gateway_integration" "proxy_any" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.proxy.id
  http_method             = aws_api_gateway_method.proxy_any.http_method
  type                    = "HTTP_PROXY"
  integration_http_method = "ANY"

  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.link.id

  uri = "http://${aws_lb.nlb.dns_name}/{proxy}"

  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }
}

# Deploy + Stage (access logs only here)
resource "aws_api_gateway_deployment" "dep" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.api.body))
  }
  depends_on = [
    aws_api_gateway_integration.healthz_proxy,
    aws_api_gateway_integration.proxy_any
  ]
}

resource "aws_api_gateway_stage" "prod" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.dep.id
  stage_name    = "prod"

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.apigw_access.arn
    format = jsonencode({
      requestId          = "$context.requestId",
      requestTime        = "$context.requestTime",
      httpMethod         = "$context.httpMethod",
      path               = "$context.path",
      status             = "$context.status",
      integrationStatus  = "$context.integrationStatus",
      integrationError   = "$context.integrationErrorMessage",
      responseLatency    = "$context.responseLatency",
      integrationLatency = "$context.integrationLatency",
      ip                 = "$context.identity.sourceIp",
      userAgent          = "$context.identity.userAgent"
    })
  }
  depends_on = [
    aws_api_gateway_account.this,
    aws_api_gateway_deployment.dep
  ]
}

# Apply logging, metrics, and throttling to ALL methods in the stage
resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_stage.prod.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled        = true
    logging_level          = "INFO" # "OFF" | "ERROR" | "INFO"
    data_trace_enabled     = false
    throttling_burst_limit = 5
    throttling_rate_limit  = 10
  }

  depends_on = [
    aws_api_gateway_stage.prod,
    aws_api_gateway_account.this
  ]
}

# API Key in API Gateway (value comes from SSM -> local.api_key_final)
resource "aws_api_gateway_api_key" "key" {
  name    = "${var.service_name}-key"
  enabled = true
  value   = local.api_key_final

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [value]
  }
}

resource "aws_api_gateway_usage_plan" "plan" {
  name  = "${var.service_name}-plan"

  throttle_settings {
    burst_limit = 5
    rate_limit  = 10
  }

  api_stages {
    api_id = aws_api_gateway_rest_api.api.id
    stage  = aws_api_gateway_stage.prod.stage_name
  }
}

resource "aws_api_gateway_usage_plan_key" "attach" {
  key_id        = aws_api_gateway_api_key.key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.plan.id
}
