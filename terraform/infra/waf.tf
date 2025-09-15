# variables assumed:
# variable "service_name" {}
# variable "region" {}

resource "aws_wafv2_web_acl" "api" {
  name        = "${var.service_name}-waf"
  description = "WAF for ${var.service_name} REST API"
  scope       = "REGIONAL"

  # ⬇️ multi-line nested blocks (required)
  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.service_name}-waf"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "AWSCommonRules"
    priority = 0

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.service_name}-common"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "IPRateLimit"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        aggregate_key_type = "IP"
        limit              = 10 # adjust as needed (requests per 5 min per IP)
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.service_name}-rate"
      sampled_requests_enabled   = true
    }
  }
}

# Associate the WAF with your REST API stage
resource "aws_wafv2_web_acl_association" "apigw" {
  resource_arn = "arn:aws:apigateway:${var.region}::/restapis/${aws_api_gateway_rest_api.api[0].id}/stages/${aws_api_gateway_stage.prod[0].stage_name}"
  web_acl_arn  = aws_wafv2_web_acl.api.arn
}
