resource "aws_cloudwatch_event_rule" "alarm_rule" {
  name = "alarm-state-change"

  event_pattern = jsonencode({
    source = ["aws.cloudwatch"],
    detail_type = ["CloudWatch Alarm State Change"]
  })
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.alarm_rule.name
  target_id = "SendToLambda"
  arn       = aws_lambda_function.jira_lambda.arn
}