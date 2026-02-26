###############################################################
# DEV Environment Infrastructure
###############################################################

module "networking" {
  source      = "../../modules/networking"
  environment = "dev"
  project     = var.project
}

module "iam" {
  source      = "../../modules/iam"
  environment = "dev"
  project     = var.project
}

module "iam_policy" {
  source      = "../../modules/iam-policy"
  environment = "dev"
  project     = var.project
}

module "github_oidc" {
  source      = "../../modules/github-oidc"
  environment = "dev"
  project     = var.project
}

module "ec2" {
  source          = "../../modules/ec2"
  environment     = "dev"
  project         = var.project
  instance_type   = var.instance_type
  vpc_id          = module.networking.vpc_id
  subnet_ids      = module.networking.private_subnets
  security_groups = module.networking.security_groups
}

module "lambda" {
  source          = "../../modules/lambda"
  environment     = "dev"
  project         = var.project
  subnet_ids      = module.networking.private_subnets
  security_groups = module.networking.lambda_sg
  memory_size     = var.lambda_memory_size
}

module "eventbridge" {
  source      = "../../modules/eventbridge"
  environment = "dev"
  project     = var.project
  lambda_arn  = module.lambda.lambda_arn
}

module "cloudwatch" {
  source      = "../../modules/cloudwatch"
  environment = "dev"
  project     = var.project
  lambda_name = module.lambda.lambda_name
}

module "sns" {
  source      = "../../modules/sns"
  environment = "dev"
  project     = var.project
  topic_name  = "${var.project}-dev-alerts"
}###############################################################
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

