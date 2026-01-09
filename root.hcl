locals {
  env = get_env("TF_VAR_ENV", "dev")

  # Extract the top level block with the env name as the key
  env_config       = yamldecode(file("${get_terragrunt_dir()}/../envs.yml"))[local.env]
  # Extract the aws_region from the env_config
  aws_region       = local.env_config["aws_region"]
  # Extract the config for the current folder (component) we are in
  component        = basename("${get_original_terragrunt_dir()}")
  component_config = local.env_config[local.component]
  # Extract the direct inputs from the component_config
  inputs           = try(local.component_config["inputs"], {})

  # Extract the env tfvar file
  env_tfvars_file = "${get_terragrunt_dir()}/../_envcommon/${local.env}.tfvars"
  # Extract the additional tfvars files from the component_config
  tfvars_files = try([for file in local.component_config["tfvar_files"] : "${get_terragrunt_dir()}/tfvars/${file}"], [])
  
  # Generate unique bucket name with account ID to avoid conflicts
  account_id = get_aws_account_id()
  state_bucket = "tf-state-${local.account_id}-${local.env}"
}

terraform_binary = "tofu"

# Generate backend configuration
remote_state {
  backend = "s3"
  
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  
  config = {
    bucket         = local.state_bucket
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.aws_region
    encrypt        = true
    dynamodb_table = "tf-locks-${local.env}"
    
    # Terragrunt will automatically create the S3 bucket
    skip_bucket_versioning         = false
    skip_bucket_ssencryption       = false
    skip_bucket_root_access        = false
    skip_bucket_enforced_tls       = false
    enable_lock_table_ssencryption = true
    
    # Optional: Enable versioning
    s3_bucket_tags = {
      Name        = "Terraform State Bucket"
      Environment = local.env
      ManagedBy   = "Terragrunt"
    }
    
    dynamodb_table_tags = {
      Name        = "Terraform Lock Table"
      Environment = local.env
      ManagedBy   = "Terragrunt"
    }
  }
}

terraform {
  extra_arguments "tfvars" {
    commands = get_terraform_commands_that_need_vars()

    optional_var_files = concat([local.env_tfvars_file], local.tfvars_files)
  }

  before_hook "before_hook" {
    commands     = ["apply", "plan", "init"]
    execute      = ["echo", "-e", "\\n\\033[1;33m====================================\\n🚀 STARTING TERRAGRUNT IN ENV: ${local.env}\\n====================================\\033[0m\\n"]
  }

  after_hook "after_hook" {
    commands     = ["apply", "plan", "init"]
    execute      = ["echo", "-e", "\\n\\033[1;32m====================================\\n✅ FINISHED TERRAGRUNT IN ENV: ${local.env}\\n====================================\\033[0m\\n"]
    run_on_error = true
  }
}

inputs = local.inputs
