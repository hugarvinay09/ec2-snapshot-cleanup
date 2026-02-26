output "ec2_private_ip" {
  value = aws_instance.app.private_ip
}

output "sns_topic_arn" {
  value = aws_sns_topic.alerts.arn
}

output "alarm_name" {
  value = aws_cloudwatch_metric_alarm.error_alarm.alarm_name
}