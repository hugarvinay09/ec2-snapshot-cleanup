########################################
# SNS Topic for EC2 Cleanup Notifications
########################################

resource "aws_sns_topic" "ec2_cleanup_topic" {
  name = "${var.project_name}-${var.environment}-ec2-cleanup-topic"

  tags = {
    Name        = "${var.project_name}-${var.environment}-ec2-cleanup-topic"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

########################################
# SNS Email Subscription
########################################

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.ec2_cleanup_topic.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

########################################
# SNS Policy (Allow CloudWatch + Lambda to Publish)
########################################

data "aws_iam_policy_document" "sns_topic_policy" {

  statement {
    sid = "AllowCloudWatchPublish"

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }

    actions = [
      "SNS:Publish"
    ]

    resources = [
      aws_sns_topic.ec2_cleanup_topic.arn
    ]
  }

  statement {
    sid = "AllowLambdaPublish"

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = [
      "SNS:Publish"
    ]

    resources = [
      aws_sns_topic.ec2_cleanup_topic.arn
    ]
  }
}

resource "aws_sns_topic_policy" "sns_policy" {
  arn    = aws_sns_topic.ec2_cleanup_topic.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}