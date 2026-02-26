###########################################################
# Terraform Remote Backend Configuration
# 3 Environments | 1 Account | 1 Region
# Remote State: S3
# Locking: DynamoDB
###########################################################

terraform {

  backend "s3" {

    # Remote State Bucket
    bucket = "my-terraform-remote-state"

    # Workspace-aware State File
    # dev  -> env/dev/terraform.tfstate
    # stage-> env/stage/terraform.tfstate
    # prod -> env/prod/terraform.tfstate
    key = "env/${terraform.workspace}/terraform.tfstate"

    region = "ap-south-1"

    # State Locking
    dynamodb_table = "terraform-state-locks"

    # Security
    encrypt        = true

    # Prevent accidental deletion of bucket
    skip_region_validation      = false
    skip_credentials_validation = false
    skip_metadata_api_check     = false
  }
}