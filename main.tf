#########################################
# Terraform Configuration
#########################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Recommended for Enterprise (Uncomment if using remote state)
  /*
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "enterprise-cicd/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
  */
}

#########################################
# AWS Provider Configuration
#########################################

provider "aws" {
  region = var.region

  # GitHub OIDC Role Assumption
  assume_role {
    role_arn = var.github_actions_role_arn
  }

  default_tags {
    tags = {
      Environment = var.environment
      Project     = "Enterprise-CICD"
      ManagedBy   = "Terraform"
      Owner       = "DevOps"
    }
  }
}

#########################################
# Data Sources
#########################################

data "aws_availability_zones" "available" {
  state = "available"
}

#########################################
# Local Values
#########################################

locals {
  az_1 = data.aws_availability_zones.available.names[0]
  az_2 = data.aws_availability_zones.available.names[1]
}