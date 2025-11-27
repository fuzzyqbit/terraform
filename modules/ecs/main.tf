# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC Module
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project_name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Security Groups
resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-alb-"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "ecs_tasks" {
  name_prefix = "${var.project_name}-ecs-tasks-"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Container port"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ecs-tasks-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Application Load Balancer Module
module "alb" {
  source = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name               = "${var.project_name}-alb"
  load_balancer_type = "application"

  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets
  security_groups = [aws_security_group.alb.id]

  listeners = merge(
    {
      ex-http = {
        port     = 80
        protocol = "HTTP"
        forward = {
          target_group_key = "ex-instance"
        }
      }
    },
    var.enable_https && var.certificate_arn != null ? {
      ex-https = {
        port            = 443
        protocol        = "HTTPS"
        certificate_arn = var.certificate_arn
        forward = {
          target_group_key = "ex-instance"
        }
      }
    } : {}
  )

  # Target Groups
  target_groups = {
    ex-instance = {
      name             = "${var.project_name}-tg"
      protocol         = "HTTP"
      port             = var.container_port
      target_type      = "ip"
      create_attachment = false

      health_check = {
        enabled             = true
        healthy_threshold   = 2
        interval            = 30
        matcher             = "200"
        path                = var.health_check_path
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        unhealthy_threshold = 2
      }
    }
  }

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-log-group"
  }
}

# ECS Module
module "ecs_cluster" {
  source = "terraform-aws-modules/ecs/aws//modules/cluster"
  version = "~> 5.0"

  cluster_name = var.project_name

  cluster_settings = var.enable_container_insights ? [
    {
      name  = "containerInsights"
      value = "enabled"
    }
  ] : []

  tags = {
    Name = "${var.project_name}-cluster"
  }
}

module "ecs_service" {
  source = "terraform-aws-modules/ecs/aws//modules/service"
  version = "~> 5.0"

  # Service
  name        = var.project_name
  cluster_arn = module.ecs_cluster.arn

  # Task Definition
  requires_compatibilities = ["FARGATE"]
  capacity_provider_strategy = {
    fargate = {
      capacity_provider = "FARGATE"
      weight            = 1
      base              = 1
    }
  }

  # Network
  subnet_ids = module.vpc.private_subnets
  security_group_rules = {
    alb_http_ingress = {
      type                     = "ingress"
      from_port                = var.container_port
      to_port                  = var.container_port
      protocol                 = "tcp"
      description              = "Service port"
      source_security_group_id = aws_security_group.alb.id
    }
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  # Container Definition(s)
  container_definitions = {
    (var.app_name) = {
      image                    = var.app_image
      readonly_root_filesystem = false

      port_mappings = [
        {
          name          = var.app_name
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]

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
    }
  }

  load_balancer = {
    service = {
      target_group_arn = module.alb.target_groups["ex-instance"].arn
      container_name   = var.app_name
      container_port   = var.container_port
    }
  }

  # Task Definition
  cpu    = var.fargate_cpu
  memory = var.fargate_memory

  # Service
  desired_count = var.desired_count
  enable_execute_command = true

  tags = {
    Name = "${var.project_name}-service"
  }
}
