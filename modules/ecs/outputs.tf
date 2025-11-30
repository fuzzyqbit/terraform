output "vpc_id" {
  description = "ID of the VPC"
  value       = var.vpc_id
}

output "load_balancer_dns_name" {
  description = "The DNS name of the load balancer"
  value       = var.alb_dns_name
}

output "load_balancer_zone_id" {
  description = "The zone ID of the load balancer"
  value       = var.alb_zone_id
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs_cluster.name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = module.ecs_cluster.arn
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.ecs_service.name
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = var.alb_target_group_arn
}

output "alb_security_group_id" {
  description = "ALB security group ID passed into the ECS module"
  value       = var.alb_security_group_id
}

output "alb_target_group_arn" {
  description = "ALB target group ARN used by the ECS service"
  value       = var.alb_target_group_arn
}

output "alb_arn" {
  description = "ALB ARN passed into the ECS module"
  value       = var.alb_arn
}

output "alb_dns_name" {
  description = "ALB DNS name passed into the ECS module"
  value       = var.alb_dns_name
}

output "alb_zone_id" {
  description = "ALB zone ID passed into the ECS module"
  value       = var.alb_zone_id
}
