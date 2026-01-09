# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

# Security Groups
resource "aws_security_group" "ecs_tasks" {
  name_prefix = "${var.project_name}-ecs-tasks-"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name     = "${var.project_name}-ecs-tasks-sg"
      yor_name = "ecs_tasks"
    },
    var.tags
  )

  lifecycle {
    create_before_destroy = true
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = var.log_retention_days

  tags = merge(
    {
      Name     = "${var.project_name}-logs"
      yor_name = "ecs_logs"
    },
    var.tags
  )
}

# ECS Cluster
module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws//modules/cluster"
  version = "~> 5.0"

  cluster_name = var.project_name

  cluster_settings = var.enable_container_insights ? [
    {
      name  = "containerInsights"
      value = "enabled"
    }
  ] : []

  tags = merge(
    {
      Name     = "${var.project_name}-cluster"
      yor_name = "ecs_cluster"
    },
    var.tags
  )
}

# ECS Service
module "ecs_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "~> 5.0"

  name        = var.project_name
  cluster_arn = module.ecs_cluster.arn

  enable_autoscaling       = true
  autoscaling_min_capacity = var.min_capacity
  autoscaling_max_capacity = var.max_capacity

  autoscaling_policies = {
    cpu = {
      name        = "${var.project_name}-cpu-autoscaling"
      policy_type = "TargetTrackingScaling"
      target_tracking_scaling_policy_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = "ECSServiceAverageCPUUtilization"
        }
        target_value = var.autoscaling_cpu_target
      }
    }
    memory = {
      name        = "${var.project_name}-memory-autoscaling"
      policy_type = "TargetTrackingScaling"
      target_tracking_scaling_policy_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = "ECSServiceAverageMemoryUtilization"
        }
        target_value = var.autoscaling_memory_target
      }
    }
  }

  requires_compatibilities = ["FARGATE"]
  capacity_provider_strategy = {
    fargate = {
      capacity_provider = "FARGATE"
      weight            = 1
      base              = 1
    }
  }

  volume = {
    apache_logs = {
      name = "apache-logs"
    }
    apache_run = {
      name = "apache-run"
    }
    tmp = {
      name = "tmp"
    }
    var_run = {
      name = "var-run"
    }
  }

  subnet_ids = var.private_subnet_ids

  security_group_rules = {
    alb_http_ingress = {
      type                     = "ingress"
      from_port                = var.container_port
      to_port                  = var.container_port
      protocol                 = "tcp"
      source_security_group_id = var.alb_security_group_id
    }
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  container_definitions = {
    (var.app_name) = {
      image = var.app_image

      port_mappings = [
        {
          name          = var.app_name
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]

      mount_points = [
        {
          sourceVolume  = "apache-logs"
          containerPath = "/usr/local/apache2/logs"
          readOnly      = false
        },
        {
          sourceVolume  = "apache-run"
          containerPath = "/usr/local/apache2/run"
          readOnly      = false
        },
        {
          sourceVolume  = "tmp"
          containerPath = "/tmp"
          readOnly      = false
        },
        {
          sourceVolume  = "var-run"
          containerPath = "/var/run"
          readOnly      = false
        }
      ]

      enable_cloudwatch_logging = true
      log_configuration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }

      environment = [
        for k, v in var.environment_variables : {
          name  = k
          value = v
        }
      ]

      secrets = [
        for k, v in var.secrets : {
          name      = k
          valueFrom = v
        }
      ]
    }
  }

  load_balancer = {
    service = {
      target_group_arn = var.alb_target_group_arn
      container_name   = var.app_name
      container_port   = var.container_port
    }
  }

  cpu    = var.fargate_cpu
  memory = var.fargate_memory

  desired_count          = var.desired_count
  enable_execute_command = true

  tags = merge(
    {
      Name     = "${var.project_name}-service"
      yor_name = "ecs_service"
    },
    var.tags
  )
}
