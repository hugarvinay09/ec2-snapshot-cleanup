###############################################################
# DEV Environment Main
###############################################################

module "networking" {
  source      = "../../modules/networking"
  project     = var.project
  environment = var.environment

  vpc_cidr       = var.vpc_cidr
  public_subnets = var.public_subnets
  private_subnets= var.private_subnets
  nat_enabled    = var.nat_enabled
}

module "iam" {
  source      = "../../modules/iam"
  project     = var.project
  environment = var.environment
}

module "iam_policy" {
  source      = "../../modules/iam-policy"
  project     = var.project
  environment = var.environment
}

module "github_oidc" {
  source      = "../../modules/github-oidc"
  project     = var.project
  environment = var.environment
  role_name   = var.github_oidc_role_name
}

module "ec2" {
  source          = "../../modules/ec2"
  project         = var.project
  environment     = var.environment
  instance_type   = var.instance_type
  ami_id          = var.ami_id
  subnet_ids      = module.networking.private_subnets
  security_groups = module.networking.security_groups
  user_data_file  = var.user_data_file
  desired_capacity= var.desired_capacity
}

module "lambda" {
  source          = "../../modules/lambda"
  project         = var.project
  environment     = var.environment
  memory_size     = var.lambda_memory_size
  subnet_ids      = module.networking.private_subnets
  security_groups = module.networking.lambda_sg
}

module "eventbridge" {
  source      = "../../modules/eventbridge"
  project     = var.project
  environment = var.environment
  lambda_arn  = module.lambda.lambda_arn
  schedule    = var.eventbridge_schedule
}

module "cloudwatch" {
  source      = "../../modules/cloudwatch"
  project     = var.project
  environment = var.environment
  lambda_name = module.lambda.lambda_name
  alarm_threshold_errors = var.alarm_threshold_errors
}

module "sns" {
  source      = "../../modules/sns"
  project     = var.project
  environment = var.environment
  topic_name  = var.sns_topic_name
}