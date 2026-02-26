############################################
# Terraform Settings
############################################

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  ############################################
  # Remote Backend Configuration
  ############################################
  backend "s3" {
    bucket         = "my-terraform-prod-state-bucket"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock-table"
    encrypt        = true
  }
}

############################################
# AWS Provider Configuration (Single Region)
############################################

provider "aws" {
  region = var.aws_region

  ############################################
  # Default Tags - Enterprise Standard
  ############################################
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "DevOps-Team"
      CostCenter  = "Cloud"
    }
  }
}

############################################
# Data Sources
############################################

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}