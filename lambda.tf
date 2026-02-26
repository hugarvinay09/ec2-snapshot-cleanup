########################################
# Archive Lambda Code
########################################

data "archive_file" "ec2_cleanup_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/ec2_cleanup.py"
  output_path = "${path.module}/lambda/ec2_cleanup.zip"
}

########################################
# IAM Role for Lambda
########################################

resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-${var.environment}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

########################################
# IAM Policy for EC2 + SNS Access
########################################

resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-${var.environment}-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [

      # EC2 permissions
      {
        Effect = "Allow",
        Action = [
          "ec2:DescribeInstances",
          "ec2:TerminateInstances",
          "ec2:DescribeSnapshots",
          "ec2:DeleteSnapshot"
        ],
        Resource = "*"
      },

      # SNS publish
      {
        Effect = "Allow",
        Action = "sns:Publish",
        Resource = aws_sns_topic.ec2_cleanup_topic.arn
      },

      # CloudWatch Logs
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}

########################################
# Lambda Function
########################################

resource "aws_lambda_function" "ec2_cleanup" {
  function_name = "${var.project_name}-${var.environment}-ec2-cleanup"

  filename         = data.archive_file.ec2_cleanup_zip.output_path
  source_code_hash = data.archive_file.ec2_cleanup_zip.output_base64sha256
  handler          = "ec2_cleanup.lambda_handler"
  runtime          = "python3.11"

  role = aws_iam_role.lambda_execution_role.arn
  timeout = 300
  memory_size = 256

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.ec2_cleanup_topic.arn
      RETENTION_DAYS = "365"
      ENVIRONMENT    = var.environment
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-ec2-cleanup"
    Environment = var.environment
    Project     = var.project_name
  }
}

########################################
# CloudWatch EventBridge Schedule (Daily)
########################################

resource "aws_cloudwatch_event_rule" "daily_trigger" {
  name                = "${var.project_name}-${var.environment}-daily-ec2-cleanup"
  schedule_expression = "rate(1 day)"
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.daily_trigger.name
  target_id = "LambdaTarget"
  arn       = aws_lambda_function.ec2_cleanup.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ec2_cleanup.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_trigger.arn
}