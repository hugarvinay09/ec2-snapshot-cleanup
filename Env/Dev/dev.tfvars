##################################
# DEV Environment Variables
##################################

# General
project          = "my-project"
environment      = "dev"
region           = "ap-south-1"

# Networking
vpc_cidr         = "10.0.0.0/16"
public_subnets   = ["10.0.1.0/24"]
private_subnets  = ["10.0.2.0/24"]
nat_enabled      = true
enable_flow_logs = true

# EC2
instance_type     = "t3.micro"
desired_capacity  = 1
ami_id            = "ami-0abcdef1234567890" # example, replace with region AMI
user_data_file    = "user-data.sh"

# Lambda
lambda_memory_size = 128

# SNS
sns_topic_name = "my-project-dev-alerts"

# CloudWatch
alarm_threshold_errors = 0

# EventBridge
eventbridge_schedule = "rate(1 day)"

# IAM/GitHub
github_oidc_role_name = "dev-github-oidc-role"