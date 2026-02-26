variable "region" {
  default = "ap-south-1"
}

variable "environment" {
  default = "dev"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "alert_email" {
  type = string
}

variable "github_actions_role_arn" {
  type = string
}