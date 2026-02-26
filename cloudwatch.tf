resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/aws/ec2/app-logs"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_metric_filter" "error_filter" {
  name           = "error-filter"
  log_group_name = aws_cloudwatch_log_group.app_logs.name
  pattern        = "ERROR"

  metric_transformation {
    name      = "ErrorCount"
    namespace = "CICD"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "error_alarm" {
  alarm_name          = "ErrorAlarm"
  metric_name         = "ErrorCount"
  namespace           = "CICD"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  alarm_actions       = [aws_sns_topic.alerts.arn]
}