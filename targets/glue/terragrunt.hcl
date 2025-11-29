# terragrunt.hcl
# Include the root terragrunt configuration
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../modules/glue"
}

dependency "vpc" {
  config_path = "../vpc"
}

inputs = merge(
  yamldecode(file(find_in_parent_folders("envs.yml")))["dev"]["glue"]["inputs"],
  {
    vpc_id     = dependency.vpc.outputs.vpc_id
    subnet_ids = dependency.vpc.outputs.private_subnets
    enable_vpc = false  # Set to true if you need VPC-enabled Glue jobs
  }
)
