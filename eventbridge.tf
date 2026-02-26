########################################
# EventBridge Rule - Daily Schedule
########################################

resource "aws_cloudwatch_event_rule" "ec2_cleanup_schedule" {
  name                = "${var.project_name}-${var.environment}-ec2-cleanup-schedule"
  description         = "Daily trigger for EC2 & Snapshot cleanup Lambda"
  schedule_expression = var.cleanup_schedule_expression
  is_enabled          = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-ec2-cleanup-schedule"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

########################################
# EventBridge Target - Lambda
########################################

resource "aws_cloudwatch_event_target" "ec2_cleanup_lambda_target" {
  rule      = aws_cloudwatch_event_rule.ec2_cleanup_schedule.name
  target_id = "ec2CleanupLambdaTarget"
  arn       = aws_lambda_function.ec2_cleanup.arn
}

########################################
# Allow EventBridge to Invoke Lambda
########################################

resource "aws_lambda_permission" "allow_eventbridge_invoke" {
  statement_id  = "AllowExecutionFromEventBridge-${var.environment}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ec2_cleanup.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ec2_cleanup_schedule.arn
}

########################################
# Dead Letter Queue (Optional - Recommended for Production)
########################################

resource "aws_sqs_queue" "eventbridge_dlq" {
  name = "${var.project_name}-${var.environment}-eventbridge-dlq"

  message_retention_seconds = 1209600 # 14 days

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_cloudwatch_event_target" "ec2_cleanup_lambda_target_with_dlq" {
  rule      = aws_cloudwatch_event_rule.ec2_cleanup_schedule.name
  target_id = "ec2CleanupLambdaTargetWithDLQ"
  arn       = aws_lambda_function.ec2_cleanup.arn

  dead_letter_config {
    arn = aws_sqs_queue.eventbridge_dlq.arn
  }

  retry_policy {
    maximum_retry_attempts       = 2
    maximum_event_age_in_seconds = 3600
  }
}