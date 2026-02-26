###############################################################
# PROD Environment Infrastructure
###############################################################

module "networking" {
  source      = "../../modules/networking"
  environment = "prod"
  project     = var.project
}

module "iam" {
  source      = "../../modules/iam"
  environment = "prod"
  project     = var.project
}

module "iam_policy" {
  source      = "../../modules/iam-policy"
  environment = "prod"
  project     = var.project
}

module "github_oidc" {
  source      = "../../modules/github-oidc"
  environment = "prod"
  project     = var.project
}

module "ec2" {
  source          = "../../modules/ec2"
  environment     = "prod"
  project         = var.project
  instance_type   = var.instance_type
  vpc_id          = module.networking.vpc_id
  subnet_ids      = module.networking.private_subnets
  security_groups = module.networking.security_groups
}

module "lambda" {
  source          = "../../modules/lambda"
  environment     = "prod"
  project         = var.project
  subnet_ids      = module.networking.private_subnets
  security_groups = module.networking.lambda_sg
  memory_size     = var.lambda_memory_size
}

module "eventbridge" {
  source      = "../../modules/eventbridge"
  environment = "prod"
  project     = var.project
  lambda_arn  = module.lambda.lambda_arn
}

module "cloudwatch" {
  source      = "../../modules/cloudwatch"
  environment = "prod"
  project     = var.project
  lambda_name = module.lambda.lambda_name
}

module "sns" {
  source      = "../../modules/sns"
  environment = "prod"
  project     = var.project
  topic_name  = "${var.project}-prod-alerts"
}