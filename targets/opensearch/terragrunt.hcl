include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../modules/opensearch"
}

# Explicit dependency - ensures VPC is deployed first
dependencies {
  paths = ["../vpc"]
}

dependency "vpc" {
  config_path = "../vpc"
  
  mock_outputs = {
    vpc_id          = "vpc-mock123"
    private_subnets = ["subnet-priv-mock1", "subnet-priv-mock2"]
    vpc_cidr_block  = "10.0.0.0/16"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "destroy"]
}

inputs = {
    vpc_id              = dependency.vpc.outputs.vpc_id
    subnet_ids          = dependency.vpc.outputs.private_subnets
    allowed_cidr_blocks = [dependency.vpc.outputs.vpc_cidr_block]
  }
