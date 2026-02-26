############################################
# LAMBDA EXECUTION POLICY
############################################

resource "aws_iam_policy" "lambda_runtime_policy" {
  name        = "${var.project_name}-${var.environment}-lambda-runtime-policy"
  description = "Allows Lambda to manage EC2 snapshots, instances and publish to SNS"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [

      # EC2 Read + Cleanup
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

      # SNS Publish
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

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

############################################
# GITHUB TERRAFORM DEPLOYMENT POLICY
############################################

resource "aws_iam_policy" "github_terraform_policy" {
  name        = "${var.project_name}-${var.environment}-github-terraform-policy"
  description = "Allows GitHub Actions to manage Terraform infrastructure"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [

      # Infrastructure Services
      {
        Effect = "Allow",
        Action = [
          "ec2:*",
          "lambda:*",
          "events:*",
          "sns:*",
          "sqs:*",
          "cloudwatch:*",
          "logs:*"
        ],
        Resource = "*"
      },

      # IAM (Controlled but required for infra deployments)
      {
        Effect = "Allow",
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:CreatePolicy",
          "iam:DeletePolicy",
          "iam:PassRole",
          "iam:GetRole",
          "iam:GetPolicy",
          "iam:GetPolicyVersion"
        ],
        Resource = "*"
      },

      # Remote Backend (S3 + DynamoDB)
      {
        Effect = "Allow",
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ],
        Resource = [
          "arn:aws:s3:::${var.project_name}-terraform-state-${var.aws_account_id}",
          "arn:aws:s3:::${var.project_name}-terraform-state-${var.aws_account_id}/*"
        ]
      },

      {
        Effect = "Allow",
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:DescribeTable"
        ],
        Resource = "arn:aws:dynamodb:${var.aws_region}:${var.aws_account_id}:table/${var.project_name}-terraform-locks"
      }
    ]
  })

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}