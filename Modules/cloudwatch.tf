############################################
# CloudWatch Log Group (Explicit)
############################################

resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.lambda.function_name}"
  retention_in_days = var.log_retention_days

  tags = {
    Environment = var.environment
  }
}

############################################
# EventBridge Rule (Scheduler)
############################################

resource "aws_cloudwatch_event_rule" "lambda_schedule" {
  count               = var.enable_schedule ? 1 : 0
  name                = "${var.environment}-lambda-schedule"
  description         = "Scheduled trigger for Lambda"
  schedule_expression = var.lambda_schedule_expression

  tags = {
    Environment = var.environment
  }
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  count = var.enable_schedule ? 1 : 0
  rule  = aws_cloudwatch_event_rule.lambda_schedule[0].name
  arn   = aws_lambda_function.lambda.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  count         = var.enable_schedule ? 1 : 0
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda_schedule[0].arn
}

############################################
# SNS Topic for Alerts (Optional)
############################################

resource "aws_sns_topic" "lambda_alerts" {
  count = var.enable_alarms && var.alarm_email != "" ? 1 : 0
  name  = "${var.environment}-lambda-alerts"

  tags = {
    Environment = var.environment
  }
}

resource "aws_sns_topic_subscription" "email_subscription" {
  count     = var.enable_alarms && var.alarm_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.lambda_alerts[0].arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

############################################
# CloudWatch Metric Alarms
############################################

# 1️⃣ Lambda Errors Alarm
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  count               = var.enable_alarms ? 1 : 0
  alarm_name          = "${var.environment}-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm when Lambda throws errors"

  dimensions = {
    FunctionName = aws_lambda_function.lambda.function_name
  }

  alarm_actions = var.alarm_email != "" ? [aws_sns_topic.lambda_alerts[0].arn] : []

  tags = {
    Environment = var.environment
  }
}

# 2️⃣ Duration Alarm
resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  count               = var.enable_alarms ? 1 : 0
  alarm_name          = "${var.environment}-lambda-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Average"
  threshold           = 10000  # 10 seconds (ms)
  alarm_description   = "Alarm if Lambda duration exceeds threshold"

  dimensions = {
    FunctionName = aws_lambda_function.lambda.function_name
  }

  alarm_actions = var.alarm_email != "" ? [aws_sns_topic.lambda_alerts[0].arn] : []

  tags = {
    Environment = var.environment
  }
}

# 3️⃣ Throttles Alarm
resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  count               = var.enable_alarms ? 1 : 0
  alarm_name          = "${var.environment}-lambda-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm when Lambda throttles occur"

  dimensions = {
    FunctionName = aws_lambda_function.lambda.function_name
  }

  alarm_actions = var.alarm_email != "" ? [aws_sns_topic.lambda_alerts[0].arn] : []

  tags = {
    Environment = var.environment
  }
}

############################################
# Metric Filter for ERROR logs (Optional)
############################################

resource "aws_cloudwatch_log_metric_filter" "error_filter" {
  name           = "${var.environment}-lambda-error-filter"
  log_group_name = aws_cloudwatch_log_group.lambda_logs.name
  pattern        = "ERROR"

  metric_transformation {
    name      = "${var.environment}-lambda-error-count"
    namespace = "Custom/Lambda"
    value     = "1"
  }
}