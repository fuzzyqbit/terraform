variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "domain_name" {
  description = "Name of the OpenSearch domain"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,27}$", var.domain_name))
    error_message = "Domain name must start with lowercase letter, contain only lowercase letters, numbers, and hyphens, and be 3-28 characters long."
  }
}

variable "engine_version" {
  description = "OpenSearch engine version"
  type        = string
  default     = "OpenSearch_2.11"
}

variable "instance_type" {
  description = "Instance type for OpenSearch nodes"
  type        = string
  default     = "t3.small.search"
}

variable "instance_count" {
  description = "Number of instances in the cluster"
  type        = number
  default     = 1

  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 80
    error_message = "Instance count must be between 1 and 80."
  }
}

variable "dedicated_master_enabled" {
  description = "Enable dedicated master nodes"
  type        = bool
  default     = false
}

variable "dedicated_master_type" {
  description = "Instance type for dedicated master nodes"
  type        = string
  default     = "t3.small.search"
}

variable "dedicated_master_count" {
  description = "Number of dedicated master nodes"
  type        = number
  default     = 3

  validation {
    condition     = contains([3, 5], var.dedicated_master_count)
    error_message = "Dedicated master count must be 3 or 5."
  }
}

variable "zone_awareness_enabled" {
  description = "Enable zone awareness (multi-AZ)"
  type        = bool
  default     = false
}

variable "availability_zone_count" {
  description = "Number of availability zones for zone awareness"
  type        = number
  default     = 2

  validation {
    condition     = contains([2, 3], var.availability_zone_count)
    error_message = "Availability zone count must be 2 or 3."
  }
}

variable "volume_size" {
  description = "EBS volume size in GB per node"
  type        = number
  default     = 10

  validation {
    condition     = var.volume_size >= 10 && var.volume_size <= 3584
    error_message = "Volume size must be between 10 and 3584 GB."
  }
}

variable "volume_type" {
  description = "EBS volume type (gp2, gp3, io1, io2)"
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.volume_type)
    error_message = "Volume type must be one of: gp2, gp3, io1, io2."
  }
}

variable "iops" {
  description = "IOPS for gp3, io1, or io2 volumes"
  type        = number
  default     = 3000

  validation {
    condition     = var.iops >= 3000 && var.iops <= 16000
    error_message = "IOPS must be between 3000 and 16000."
  }
}

variable "throughput" {
  description = "Throughput for gp3 volumes in MiB/s"
  type        = number
  default     = 125

  validation {
    condition     = var.throughput >= 125 && var.throughput <= 1000
    error_message = "Throughput must be between 125 and 1000 MiB/s."
  }
}

variable "master_user_name" {
  description = "Master username for OpenSearch fine-grained access control"
  type        = string
  sensitive   = true
}

variable "master_user_password" {
  description = "Master password for OpenSearch fine-grained access control (min 8 chars, must include uppercase, lowercase, number, and special char)"
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^.{8,}$", var.master_user_password))
    error_message = "Password must be at least 8 characters long."
  }
}

variable "vpc_id" {
  description = "VPC ID where OpenSearch will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for OpenSearch (must be in different AZs if zone awareness is enabled)"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 1
    error_message = "At least one subnet ID is required."
  }
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access OpenSearch"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "force_destroy_bucket" {
  description = "Allow destruction of non-empty S3 bucket (use with caution)"
  type        = bool
  default     = false
}

variable "auto_load_data" {
  description = "Automatically load sample data after OpenSearch cluster is created"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
