resource "aws_lb" "main" {
  name               = var.alb_name
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.subnet_ids

  tags = merge(var.tags, {
    git_commit           = "12debb0bb8e9b7c8231270cf74bf415ad42f1199"
    git_file             = "modules/alb/main.tf"
    git_last_modified_at = "2025-11-30 03:14:51"
    git_last_modified_by = "quantum@koala.io"
    git_modifiers        = "quantum"
    git_org              = "fuzzyqbit"
    git_repo             = "terraform"
    yor_name             = "main"
    yor_trace            = "9d383a04-3fe9-4402-9443-952c1782df89"
  })
}

resource "aws_security_group" "alb" {
  name        = "${var.alb_name}-sg"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    git_commit           = "12debb0bb8e9b7c8231270cf74bf415ad42f1199"
    git_file             = "modules/alb/main.tf"
    git_last_modified_at = "2025-11-30 03:14:51"
    git_last_modified_by = "quantum@koala.io"
    git_modifiers        = "quantum"
    git_org              = "fuzzyqbit"
    git_repo             = "terraform"
    yor_name             = "alb"
    yor_trace            = "a987ec2a-f842-4b03-97ea-7799278f9a08"
  })
}

resource "aws_lb_target_group" "main" {
  name        = var.target_group_name
  port        = var.target_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  tags = merge(var.tags, {
    git_commit           = "12debb0bb8e9b7c8231270cf74bf415ad42f1199"
    git_file             = "modules/alb/main.tf"
    git_last_modified_at = "2025-11-30 03:14:51"
    git_last_modified_by = "quantum@koala.io"
    git_modifiers        = "quantum"
    git_org              = "fuzzyqbit"
    git_repo             = "terraform"
    yor_name             = "main"
    yor_trace            = "ac2b539c-8360-4321-bde7-f94065da9c99"
  })
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  tags = var.tags
}