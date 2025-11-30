# terragrunt.hcl
# Include the root terragrunt configuration
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../modules/alb"
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id         = "vpc-mock"
    public_subnets = ["subnet-mock1", "subnet-mock2"]
  }
}


inputs = {
    vpc_id     = dependency.vpc.outputs.vpc_id
    subnet_ids = dependency.vpc.outputs.public_subnets
}