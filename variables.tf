variable "region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "Environment name (dev/qa/prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs"
  type        = list(string)
}

variable "lambda_zip_path" {
  description = "Path to Lambda zip file"
  type        = string
}

variable "lambda_handler" {
  description = "Lambda handler"
  type        = string
}

variable "lambda_runtime" {
  description = "Lambda runtime"
  type        = string
}

variable "lambda_environment_variables" {
  description = "Environment variables for Lambda"
  type        = map(string)
  default     = {}
}

variable "enable_schedule" {
  description = "Enable CloudWatch schedule trigger"
  type        = bool
}

variable "lambda_schedule_expression" {
  description = "CloudWatch schedule expression"
  type        = string
  default     = "rate(5 minutes)"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = string
}

variable "create_public_ec2" {
  description = "Deploy EC2 in public subnet"
  type        = bool
}

variable "ec2_ami_id" {
  description = "AMI ID"
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 14
}

variable "alarm_email" {
  description = "Email for CloudWatch alarm notifications"
  type        = string
  default     = ""
}

variable "enable_alarms" {
  description = "Enable CloudWatch alarms"
  type        = bool
  default     = true
}
variable "project_name" {
  description = "Project name"
  type        = string
}

variable "notification_email" {
  description = "Email to receive SNS alerts"
  type        = string
}

variable "cleanup_schedule_expression" {
  description = "EventBridge schedule expression"
  type        = string
  default     = "rate(1 day)"
}

variable "github_repository" {
  description = "GitHub repository in format: org/repo"
  type        = string
}

variable "github_branch" {
  description = "Allowed GitHub branch for deployment"
  type        = string
  default     = "main"
}

