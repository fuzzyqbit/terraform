variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "glue_version" {
  description = "Glue version"
  type        = string
  default     = "4.0"
}

variable "python_version" {
  description = "Python version for Glue jobs"
  type        = string
  default     = "3"
}

variable "max_retries" {
  description = "Maximum number of times to retry a job"
  type        = number
  default     = 1
}

variable "timeout_minutes" {
  description = "Job timeout in minutes"
  type        = number
  default     = 60
}

variable "worker_type" {
  description = "Type of predefined worker (G.1X, G.2X, G.025X, etc.)"
  type        = string
  default     = "G.1X"
}

variable "number_of_workers" {
  description = "Number of workers"
  type        = number
  default     = 2
}

variable "enable_continuous_log_filter" {
  description = "Enable continuous logging"
  type        = bool
  default     = true
}

variable "enable_metrics" {
  description = "Enable CloudWatch metrics"
  type        = bool
  default     = true
}

variable "enable_spark_ui" {
  description = "Enable Spark UI"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}

variable "common_tags" {
  description = "Common tags including Yor tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "download_sample_data" {
  description = "Whether to download NYC taxi sample data"
  type        = bool
  default     = true
}

variable "sample_data_year" {
  description = "Year of NYC taxi data to download"
  type        = number
  default     = 2024
}

variable "sample_data_month" {
  description = "Month of NYC taxi data to download"
  type        = number
  default     = 1
}
