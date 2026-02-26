############################################
# LAMBDA EXECUTION ROLE
############################################

resource "aws_iam_role" "lambda_execution_role" {
  name = "${var.project_name}-${var.environment}-lambda-execution-role"

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

############################################
# LAMBDA IAM POLICY (Least Privilege)
############################################

resource "aws_iam_policy" "lambda_policy" {
  name = "${var.project_name}-${var.environment}-lambda-policy"

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
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

############################################
# ATTACH BASIC AWS MANAGED POLICY (Optional but recommended)
############################################

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

############################################
# GITHUB OIDC ROLE
############################################

resource "aws_iam_role" "github_actions_role" {
  name = "${var.project_name}-${var.environment}-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          },
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repository}:ref:refs/heads/${var.github_branch}"
          }
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

############################################
# GITHUB TERRAFORM DEPLOYMENT POLICY
############################################

resource "aws_iam_policy" "github_terraform_policy" {
  name = "${var.project_name}-${var.environment}-github-terraform-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [

      {
        Effect = "Allow",
        Action = [
          "ec2:*",
          "lambda:*",
          "iam:*",
          "events:*",
          "sns:*",
          "sqs:*",
          "logs:*",
          "cloudwatch:*",
          "dynamodb:*",
          "s3:*"
        ],
        Resource = "*"
      }
    ]
  })

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "github_policy_attach" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = aws_iam_policy.github_terraform_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_runtime_attach" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_runtime_policy.arn
}

