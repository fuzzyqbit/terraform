# terragrunt.hcl
# Include the root terragrunt configuration
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../modules/ecs"
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id           = "vpc-mock"
    public_subnets   = ["subnet-pub-mock1", "subnet-pub-mock2"]
    private_subnets  = ["subnet-priv-mock1", "subnet-priv-mock2"]
  }
}

dependency "alb" {
  config_path = "../alb"

  mock_outputs = {
    security_group_id = "sg-mock"
    target_group_arn  = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/mock/mock"
    arn              = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/mock/mock"
    dns_name         = "mock-alb.elb.amazonaws.com"
    zone_id          = "Z1234567890ABC"
  }
}


inputs = {
    vpc_id                = dependency.vpc.outputs.vpc_id
    public_subnet_ids     = dependency.vpc.outputs.public_subnets
    private_subnet_ids    = dependency.vpc.outputs.private_subnets
    alb_security_group_id = dependency.alb.outputs.security_group_id
    alb_target_group_arn  = dependency.alb.outputs.target_group_arn
    alb_arn              = dependency.alb.outputs.arn
    alb_dns_name         = dependency.alb.outputs.dns_name
    alb_zone_id          = dependency.alb.outputs.zone_id
  }
