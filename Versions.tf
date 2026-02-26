#############################################################
# Terraform & Provider Version Constraints
# 3 Environments | 1 Account | 1 Region
#############################################################

terraform {

  ###########################################################
  # Required Terraform CLI Version
  ###########################################################
  required_version = ">= 1.6.0"

  ###########################################################
  # Required Providers
  ###########################################################
  required_providers {

    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    #########################################################
    # Optional but Recommended Providers (Best Practice)
    #########################################################

    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }

    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }

  ###########################################################
  # CLI Configuration (Optional Best Practice)
  ###########################################################
  experiments = []
}