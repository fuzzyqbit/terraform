data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr

  azs             = slice(data.aws_availability_zones.available.names, 0, var.az_count)
  public_subnets  = var.public_subnet_cidrs
  private_subnets = var.private_subnet_cidrs

  enable_nat_gateway   = var.enable_nat_gateway
  enable_vpn_gateway   = var.enable_vpn_gateway
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-vpc"
      Environment = var.environment
    },
    var.tags
    , {
      git_commit           = "e94698fc6d036ffe61058c748a3db3c69a698b3e"
      git_file             = "modules/vpc/main.tf"
      git_last_modified_at = "2025-11-28 23:15:55"
      git_last_modified_by = "quantum@koala.io"
      git_modifiers        = "quantum"
      git_org              = "fuzzyqbit"
      git_repo             = "terraform"
      yor_name             = "vpc"
      yor_trace            = "3b15cad9-6b7e-460e-83a4-15fe04a5946b"
  })
}