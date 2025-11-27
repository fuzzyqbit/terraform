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
  tfvars_files     = try([for file in local.component_config["tfvar_files"]: "${get_terragrunt_dir()}/tfvars/${file}"], [])
}

terraform_binary = "tofu"

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

inputs = merge(local.inputs, {})
