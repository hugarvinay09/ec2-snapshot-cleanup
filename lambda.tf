resource "aws_iam_role" "lambda_role" {
  name = "lambda-jira-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Principal = { Service = "lambda.amazonaws.com" }
      Effect = "Allow"
    }]
  })
}

resource "aws_lambda_function" "jira_lambda" {
  function_name = "jira-ticket-creator"
  runtime       = "python3.11"
  handler       = "index.lambda_handler"
  role          = aws_iam_role.lambda_role.arn
  filename      = "lambda.zip"
}