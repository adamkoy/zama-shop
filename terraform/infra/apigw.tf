############################
# API Gateway (REST) + Key #
############################

locals {
  enable_apigw = true
}

resource "aws_cloudwatch_log_group" "apigw_access" {
  count             = local.enable_apigw ? 1 : 0
  name              = "/apigw/${var.service_name}/access"
  retention_in_days = 7
}

resource "aws_api_gateway_rest_api" "api" {
  count = local.enable_apigw ? 1 : 0
  name  = "${var.service_name}-gw"
}

# /healthz (open)
resource "aws_api_gateway_resource" "healthz" {
  count       = local.enable_apigw ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.api[0].id
  parent_id   = aws_api_gateway_rest_api.api[0].root_resource_id
  path_part   = "healthz"
}

resource "aws_api_gateway_method" "healthz_get" {
  count            = local.enable_apigw ? 1 : 0
  rest_api_id      = aws_api_gateway_rest_api.api[0].id
  resource_id      = aws_api_gateway_resource.healthz[0].id
  http_method      = "GET"
  authorization    = "NONE"
  api_key_required = false
}

resource "aws_api_gateway_integration" "healthz_proxy" {
  count                   = local.enable_apigw ? 1 : 0
  rest_api_id             = aws_api_gateway_rest_api.api[0].id
  resource_id             = aws_api_gateway_resource.healthz[0].id
  http_method             = aws_api_gateway_method.healthz_get[0].http_method
  type                    = "HTTP_PROXY"
  integration_http_method = "GET"
  uri                     = "http://${aws_lb.this.dns_name}/healthz"
}

# {proxy+} — requires API key
resource "aws_api_gateway_resource" "proxy" {
  count       = local.enable_apigw ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.api[0].id
  parent_id   = aws_api_gateway_rest_api.api[0].root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy_any" {
  count            = local.enable_apigw ? 1 : 0
  rest_api_id      = aws_api_gateway_rest_api.api[0].id
  resource_id      = aws_api_gateway_resource.proxy[0].id
  http_method      = "ANY"
  authorization    = "NONE"
  api_key_required = true

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "proxy_any" {
  count                   = local.enable_apigw ? 1 : 0
  rest_api_id             = aws_api_gateway_rest_api.api[0].id
  resource_id             = aws_api_gateway_resource.proxy[0].id
  http_method             = aws_api_gateway_method.proxy_any[0].http_method
  type                    = "HTTP_PROXY"
  integration_http_method = "ANY"
  uri                     = "http://${aws_lb.this.dns_name}/{proxy}"

  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }
}

# Deploy + Stage (access logs only here)
resource "aws_api_gateway_deployment" "dep" {
  count       = local.enable_apigw ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.api[0].id
  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.api[0].body))
  }
  depends_on = [
    aws_api_gateway_integration.healthz_proxy,
    aws_api_gateway_integration.proxy_any
  ]
}

resource "aws_api_gateway_stage" "prod" {
  count         = local.enable_apigw ? 1 : 0
  rest_api_id   = aws_api_gateway_rest_api.api[0].id
  deployment_id = aws_api_gateway_deployment.dep[0].id
  stage_name    = "prod"

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.apigw_access[0].arn
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
  rest_api_id = aws_api_gateway_rest_api.api[0].id
  stage_name  = aws_api_gateway_stage.prod[0].stage_name
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
  count   = local.enable_apigw ? 1 : 0
  name    = "${var.service_name}-key"
  enabled = true
  value   = local.api_key_final

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [value]
  }
}

resource "aws_api_gateway_usage_plan" "plan" {
  count = local.enable_apigw ? 1 : 0
  name  = "${var.service_name}-plan"

  throttle_settings {
    burst_limit = 5
    rate_limit  = 10
  }

  api_stages {
    api_id = aws_api_gateway_rest_api.api[0].id
    stage  = aws_api_gateway_stage.prod[0].stage_name
  }
}

resource "aws_api_gateway_usage_plan_key" "attach" {
  count         = local.enable_apigw ? 1 : 0
  key_id        = aws_api_gateway_api_key.key[0].id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.plan[0].id
}

output "api_base_url" {
  value       = local.enable_apigw ? "https://${aws_api_gateway_rest_api.api[0].id}.execute-api.${var.region}.amazonaws.com/${aws_api_gateway_stage.prod[0].stage_name}/" : null
  description = "API Gateway base URL"
}

output "api_key_value_effective" {
  value     = local.api_key_final
  sensitive = true
}
