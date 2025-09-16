resource "aws_sns_topic" "alerts" {
  count = var.sns_topic_arn == null ? 1 : 0
  name  = "${var.service_name}-alerts"
}

# Optional email subscription (only if you provide alert_email)
resource "aws_sns_topic_subscription" "alerts_email" {
  count     = var.alert_email == null ? 0 : 1
  topic_arn = coalesce(var.sns_topic_arn, aws_sns_topic.alerts[0].arn)
  protocol  = "email"
  endpoint  = var.alert_email
}

# Unified topic ARN to use below
locals {
  alarm_topic_arn = coalesce(var.sns_topic_arn, try(aws_sns_topic.alerts[0].arn, null))
}

############################
# CloudWatch Alarm (REST API)
############################
# NOTE: For REST APIs, use metric_name = "5XXError" and dimensions ApiName + Stage.
# For HTTP APIs (v2), use metric_name = "5xx" and dimensions ApiId + Stage.

resource "aws_cloudwatch_metric_alarm" "apigw_5xx_rate" {
  alarm_name          = "${var.service_name}-apigw-5xx-rate"
  alarm_description   = "5xx rate > 1% (5 min window)"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 1
  evaluation_periods  = 5
  datapoints_to_alarm = 3
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_topic_arn == null ? [] : [local.alarm_topic_arn]

  # m1: REST 5XX errors
  metric_query {
    id = "m1"
    metric {
      namespace   = "AWS/ApiGateway"
      metric_name = "5XXError"
      period      = 60
      stat        = "Sum"
      dimensions = {
        ApiName = aws_api_gateway_rest_api.api[0].name
        Stage   = aws_api_gateway_stage.prod[0].stage_name
      }
    }
  }

  # m2: total request Count
  metric_query {
    id = "m2"
    metric {
      namespace   = "AWS/ApiGateway"
      metric_name = "Count"
      period      = 60
      stat        = "Sum"
      dimensions = {
        ApiName = aws_api_gateway_rest_api.api[0].name
        Stage   = aws_api_gateway_stage.prod[0].stage_name
      }
    }
  }

  # e1: 100 * (5xx / total)
  metric_query {
    id          = "e1"
    expression  = "100*(m1/m2)"
    label       = "5xx rate (%)"
    return_data = true
  }
}
