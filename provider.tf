############################################
# Terraform Settings
############################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  ##########################################
  # Remote Backend (Single Account, 1 Region)
  ##########################################
  backend "s3" {
    bucket         = "my-terraform-remote-state-bucket"
    key            = "lambda-vpc/${var.environment}/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

############################################
# AWS Provider
############################################

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = "lambda-vpc-project"
      ManagedBy   = "Terraform"
    }
  }
}