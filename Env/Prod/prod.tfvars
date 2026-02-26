##################################
# PROD Environment Variables
##################################

project          = "my-project"
environment      = "prod"
region           = "ap-south-1"

# Networking
vpc_cidr         = "10.2.0.0/16"
public_subnets   = ["10.2.1.0/24"]
private_subnets  = ["10.2.2.0/24"]
nat_enabled      = true
enable_flow_logs = true

# EC2
instance_type     = "t3.medium"
desired_capacity  = 3
ami_id            = "ami-0abcdef1234567890"
user_data_file    = "user-data.sh"

# Lambda
lambda_memory_size = 512

# SNS
sns_topic_name = "my-project-prod-alerts"

# CloudWatch
alarm_threshold_errors = 0

# EventBridge
eventbridge_schedule = "rate(1 day)"

# IAM/GitHub
github_oidc_role_name = "prod-github-oidc-role"