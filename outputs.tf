############################################
# General
############################################

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "region" {
  description = "AWS region"
  value       = var.region
}

############################################
# VPC Outputs
############################################

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

############################################
# Subnets
############################################

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "public_subnet_cidrs" {
  description = "Public subnet CIDRs"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_cidrs" {
  description = "Private subnet CIDRs"
  value       = aws_subnet.private[*].cidr_block
}

############################################
# Internet + NAT
############################################

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.igw.id
}

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = aws_nat_gateway.nat.id
}

output "nat_public_ip" {
  description = "Elastic IP associated with NAT Gateway"
  value       = aws_eip.nat_eip.public_ip
}

############################################
# Route Tables
############################################

output "public_route_table_id" {
  description = "Public route table ID"
  value       = aws_route_table.public_rt.id
}

output "private_route_table_id" {
  description = "Private route table ID"
  value       = aws_route_table.private_rt.id
}

############################################
# Security Group
############################################

output "lambda_security_group_id" {
  description = "Lambda Security Group ID"
  value       = aws_security_group.lambda_sg.id
}

############################################
# IAM
############################################

output "lambda_role_name" {
  description = "Lambda IAM Role Name"
  value       = aws_iam_role.lambda_role.name
}

output "lambda_role_arn" {
  description = "Lambda IAM Role ARN"
  value       = aws_iam_role.lambda_role.arn
}

############################################
# Lambda Function
############################################

output "lambda_function_name" {
  description = "Lambda Function Name"
  value       = aws_lambda_function.lambda.function_name
}

output "lambda_function_arn" {
  description = "Lambda Function ARN"
  value       = aws_lambda_function.lambda.arn
}

output "lambda_invoke_arn" {
  description = "Lambda Invoke ARN"
  value       = aws_lambda_function.lambda.invoke_arn
}

############################################
# EventBridge (Optional)
############################################

output "eventbridge_rule_name" {
  description = "EventBridge rule name"
  value       = var.enable_schedule ? aws_cloudwatch_event_rule.lambda_schedule[0].name : null
}

output "eventbridge_rule_arn" {
  description = "EventBridge rule ARN"
  value       = var.enable_schedule ? aws_cloudwatch_event_rule.lambda_schedule[0].arn : null
}