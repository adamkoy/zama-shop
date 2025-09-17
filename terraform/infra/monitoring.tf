resource "aws_sns_topic" "alerts" {
  name = "${var.service_name}-alerts"
}

# Optional email subscription (only if you provide alert_email)
resource "aws_sns_topic_subscription" "alerts_email" {
  topic_arn = coalesce(var.sns_topic_arn, aws_sns_topic.alerts.arn)
  protocol  = "email"
  endpoint  = var.alert_email
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
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  # m1: REST 5XX errors
  metric_query {
    id = "m1"
    metric {
      namespace   = "AWS/ApiGateway"
      metric_name = "5XXError"
      period      = 60
      stat        = "Sum"
      dimensions = {
        ApiName = aws_api_gateway_rest_api.api.name
        Stage   = aws_api_gateway_stage.prod.stage_name
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
        ApiName = aws_api_gateway_rest_api.api.name
        Stage   = aws_api_gateway_stage.prod.stage_name
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
