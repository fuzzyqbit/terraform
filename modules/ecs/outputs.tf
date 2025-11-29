output "vpc_id" {
  description = "ID of the VPC"
  value       = var.vpc_id
}

output "load_balancer_dns_name" {
  description = "The DNS name of the load balancer"
  value       = module.alb.dns_name
}

output "load_balancer_zone_id" {
  description = "The zone ID of the load balancer"
  value       = module.alb.zone_id
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
  value       = module.alb.target_groups["ex-instance"].arn
}
