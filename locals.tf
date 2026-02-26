###############################################
# Locals – Centralized Configuration
# 3 Environments | 1 Account | 1 Region
###############################################

locals {

  #################################################
  # Environment Detection
  #################################################

  environment = terraform.workspace

  #################################################
  # Naming Convention
  #################################################

  name_prefix = "${var.project}-${local.environment}"

  #################################################
  # Account Details
  #################################################

  account_id = data.aws_caller_identity.current.account_id

  #################################################
  # Standard Tags (Enterprise Standard)
  #################################################

  common_tags = {
    Project       = var.project
    Environment   = local.environment
    ManagedBy     = "Terraform"
    Repository    = "github-actions-oidc"
    AccountID     = local.account_id
    CostCenter    = var.project
    Owner         = "DevOps-Team"
  }

  #################################################
  # Environment Based Instance Sizing
  #################################################

  instance_type_map = {
    dev   = "t3.micro"
    stage = "t3.small"
    prod  = "t3.medium"
  }

  instance_type = lookup(
    local.instance_type_map,
    local.environment,
    "t3.micro"
  )

  #################################################
  # Environment Based Desired Capacity
  #################################################

  desired_capacity_map = {
    dev   = 1
    stage = 2
    prod  = 3
  }

  desired_capacity = lookup(
    local.desired_capacity_map,
    local.environment,
    1
  )

  #################################################
  # Environment Based RDS Storage
  #################################################

  rds_allocated_storage_map = {
    dev   = 20
    stage = 50
    prod  = 100
  }

  rds_allocated_storage = lookup(
    local.rds_allocated_storage_map,
    local.environment,
    20
  )

  #################################################
  # Lambda Reserved Concurrency
  #################################################

  lambda_reserved_concurrency_map = {
    dev   = 1
    stage = 5
    prod  = 20
  }

  lambda_reserved_concurrency = lookup(
    local.lambda_reserved_concurrency_map,
    local.environment,
    1
  )

  #################################################
  # Security Configuration Flags
  #################################################

  enable_termination_protection = local.environment == "prod" ? true : false

  enable_deletion_protection    = local.environment == "prod" ? true : false

  enable_multi_az               = local.environment == "prod" ? true : false

  #################################################
  # S3 State Key Convention
  #################################################

  state_key = "env/${local.environment}/terraform.tfstate"

}