###############################################################
# Lambda Function for EC2 & Snapshot Cleanup
###############################################################

variable "project" {}
variable "environment" {}
variable "memory_size" {}
variable "subnet_ids" {
  type = list(string)
}
variable "security_groups" {
  type = list(string)
}
variable "sns_topic_arn" {}
variable "retention_days" {
  default = 365
}
variable "dry_run" {
  default = true
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_exec_role" {
  name               = "${var.project}-${var.environment}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# Attach Managed Policies
resource "aws_iam_role_policy_attachment" "lambda_basic_exec" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_ec2_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_sns_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
}

# Lambda Function
resource "aws_lambda_function" "ec2_snapshot_cleanup" {
  function_name = "${var.project}-${var.environment}-ec2-snapshot-cleanup"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"
  memory_size   = var.memory_size
  timeout       = 900  # 15 min max

  filename      = "lambda.zip"  # Build zip with deployment package

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = var.security_groups
  }

  environment {
    variables = {
      RETENTION_DAYS  = var.retention_days
      DRY_RUN         = var.dry_run
      SNS_TOPIC_ARN   = var.sns_topic_arn
      ENVIRONMENT     = var.environment
    }
  }

  depends_on = [aws_iam_role_policy_attachment.lambda_basic_exec]
}

# EventBridge Rule (Daily Trigger)
resource "aws_cloudwatch_event_rule" "daily_lambda_trigger" {
  name                = "${var.project}-${var.environment}-daily-lambda-trigger"
  schedule_expression = "rate(1 day)"
}

# EventBridge Target
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.daily_lambda_trigger.name
  target_id = "ec2-snapshot-cleanup"
  arn       = aws_lambda_function.ec2_snapshot_cleanup.arn
}

# Lambda Permission for EventBridge
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ec2_snapshot_cleanup.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_lambda_trigger.arn
}