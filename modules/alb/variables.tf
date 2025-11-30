variable "alb_name" {
  description = "Name of the load balancer"
  type        = string
}

variable "internal" {
  description = "Whether the load balancer is internal"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the load balancer"
  type        = list(string)
}

variable "target_group_name" {
  description = "Name of the target group"
  type        = string
}

variable "target_port" {
  description = "Port for the target group"
  type        = number
  default     = 80
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}