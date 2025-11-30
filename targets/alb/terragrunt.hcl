# terragrunt.hcl
# Include the root terragrunt configuration
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../modules/alb"
}
