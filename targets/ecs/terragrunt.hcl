# terragrunt.hcl
# Include the root terragrunt configuration
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../modules/ecs/"
}

# Generate provider configuration
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  
}


EOF
}
# Input variables
inputs = {}
