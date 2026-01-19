data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Use existing Service-Linked Role for OpenSearch
data "aws_iam_role" "opensearch_slr" {
  name = "AWSServiceRoleForAmazonOpenSearchService"
}

# Security Group for OpenSearch
resource "aws_security_group" "opensearch" {
  name_prefix = "${var.project_name}-opensearch-"
  description = "Security group for OpenSearch domain"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name = "${var.project_name}-opensearch-sg"
    },
    var.tags
  )

  lifecycle {
    create_before_destroy = true
  }
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "opensearch" {
  name              = "/aws/opensearch/${var.domain_name}/index-slow-logs"
  retention_in_days = 7
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "opensearch_app" {
  name              = "/aws/opensearch/${var.domain_name}/search-slow-logs"
  retention_in_days = 7
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "opensearch_error" {
  name              = "/aws/opensearch/${var.domain_name}/application-logs"
  retention_in_days = 7
  tags              = var.tags
}

# IAM Policy for CloudWatch Logs
data "aws_iam_policy_document" "opensearch_log_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["es.amazonaws.com"]
    }
    actions = [
      "logs:PutLogEvents",
      "logs:CreateLogStream"
    ]
    resources = [
      "${aws_cloudwatch_log_group.opensearch.arn}:*",
      "${aws_cloudwatch_log_group.opensearch_app.arn}:*",
      "${aws_cloudwatch_log_group.opensearch_error.arn}:*"
    ]
  }
}

resource "aws_cloudwatch_log_resource_policy" "opensearch" {
  policy_name     = "${var.domain_name}-log-policy"
  policy_document = data.aws_iam_policy_document.opensearch_log_policy.json
}

# OpenSearch Domain
resource "aws_opensearch_domain" "main" {
  domain_name    = var.domain_name
  engine_version = var.engine_version

  cluster_config {
    instance_type            = var.instance_type
    instance_count           = var.instance_count
    dedicated_master_enabled = var.dedicated_master_enabled
    dedicated_master_type    = var.dedicated_master_enabled ? var.dedicated_master_type : null
    dedicated_master_count   = var.dedicated_master_enabled ? var.dedicated_master_count : null
    zone_awareness_enabled   = var.zone_awareness_enabled

    dynamic "zone_awareness_config" {
      for_each = var.zone_awareness_enabled ? [1] : []
      content {
        availability_zone_count = var.availability_zone_count
      }
    }
  }

  vpc_options {
    subnet_ids         = var.zone_awareness_enabled ? slice(var.subnet_ids, 0, var.availability_zone_count) : [var.subnet_ids[0]]
    security_group_ids = [aws_security_group.opensearch.id]
  }

  ebs_options {
    ebs_enabled = true
    volume_size = var.volume_size
    volume_type = var.volume_type
    iops        = var.volume_type == "gp3" ? var.iops : null
    throughput  = var.volume_type == "gp3" ? var.throughput : null
  }

  encrypt_at_rest {
    enabled = true
  }

  node_to_node_encryption {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  advanced_security_options {
    enabled                        = true
    internal_user_database_enabled = true
    master_user_options {
      master_user_name     = var.master_user_name
      master_user_password = var.master_user_password
    }
  }

  access_policies = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action   = "es:*"
        Resource = "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${var.domain_name}/*"
      }
    ]
  })

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch.arn
    log_type                 = "INDEX_SLOW_LOGS"
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch_app.arn
    log_type                 = "SEARCH_SLOW_LOGS"
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch_error.arn
    log_type                 = "ES_APPLICATION_LOGS"
  }

  tags = merge(
    {
      Name = var.domain_name
    },
    var.tags
  )

  depends_on = [
    data.aws_iam_role.opensearch_slr,
    aws_cloudwatch_log_group.opensearch,
    aws_cloudwatch_log_group.opensearch_app,
    aws_cloudwatch_log_group.opensearch_error,
    aws_cloudwatch_log_resource_policy.opensearch
  ]
}

# S3 bucket for sample data
module "s3_sample_data" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  bucket        = "${var.project_name}-opensearch-data-${data.aws_caller_identity.current.account_id}"
  force_destroy = var.force_destroy_bucket

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = merge(
    {
      Name = "${var.project_name}-opensearch-data"
    },
    var.tags
  )
}

# Upload sample movies data
resource "aws_s3_object" "movies_data" {
  bucket  = module.s3_sample_data.s3_bucket_id
  key     = "data/movies.json"
  content = jsonencode([
    {
      title       = "The Shawshank Redemption"
      year        = 1994
      genre       = ["Drama"]
      director    = "Frank Darabont"
      rating      = 9.3
      description = "Two imprisoned men bond over a number of years, finding solace and eventual redemption through acts of common decency."
    },
    {
      title       = "The Godfather"
      year        = 1972
      genre       = ["Crime", "Drama"]
      director    = "Francis Ford Coppola"
      rating      = 9.2
      description = "The aging patriarch of an organized crime dynasty transfers control of his clandestine empire to his reluctant son."
    },
    {
      title       = "The Dark Knight"
      year        = 2008
      genre       = ["Action", "Crime", "Drama"]
      director    = "Christopher Nolan"
      rating      = 9.0
      description = "When the menace known as the Joker wreaks havoc on Gotham, Batman must accept one of the greatest psychological tests."
    },
    {
      title       = "Pulp Fiction"
      year        = 1994
      genre       = ["Crime", "Drama"]
      director    = "Quentin Tarantino"
      rating      = 8.9
      description = "The lives of two mob hitmen, a boxer, a gangster and his wife intertwine in four tales of violence and redemption."
    },
    {
      title       = "Forrest Gump"
      year        = 1994
      genre       = ["Drama", "Romance"]
      director    = "Robert Zemeckis"
      rating      = 8.8
      description = "The presidencies of Kennedy and Johnson unfold through the perspective of an Alabama man with an IQ of 75."
    },
    {
      title       = "Inception"
      year        = 2010
      genre       = ["Action", "Sci-Fi", "Thriller"]
      director    = "Christopher Nolan"
      rating      = 8.8
      description = "A thief who steals corporate secrets through dream-sharing technology is given the task of planting an idea."
    },
    {
      title       = "The Matrix"
      year        = 1999
      genre       = ["Action", "Sci-Fi"]
      director    = "Lana Wachowski, Lilly Wachowski"
      rating      = 8.7
      description = "A computer hacker learns about the true nature of his reality and his role in the war against its controllers."
    },
    {
      title       = "Goodfellas"
      year        = 1990
      genre       = ["Biography", "Crime", "Drama"]
      director    = "Martin Scorsese"
      rating      = 8.7
      description = "The story of Henry Hill and his life in the mob, covering his relationship with his wife and mob partners."
    },
    {
      title       = "Interstellar"
      year        = 2014
      genre       = ["Adventure", "Drama", "Sci-Fi"]
      director    = "Christopher Nolan"
      rating      = 8.6
      description = "A team of explorers travel through a wormhole in space to ensure humanity's survival."
    },
    {
      title       = "The Lord of the Rings: The Return of the King"
      year        = 2003
      genre       = ["Action", "Adventure", "Drama"]
      director    = "Peter Jackson"
      rating      = 9.0
      description = "Gandalf and Aragorn lead the World of Men against Sauron's army to draw his gaze from Frodo and Sam."
    },
    {
      title       = "Fight Club"
      year        = 1999
      genre       = ["Drama"]
      director    = "David Fincher"
      rating      = 8.8
      description = "An insomniac office worker and a devil-may-care soap maker form an underground fight club."
    },
    {
      title       = "Star Wars: Episode V"
      year        = 1980
      genre       = ["Action", "Adventure", "Fantasy"]
      director    = "Irvin Kershner"
      rating      = 8.7
      description = "After the Rebels are brutally overpowered by the Empire, Luke Skywalker begins Jedi training with Yoda."
    },
    {
      title       = "The Silence of the Lambs"
      year        = 1991
      genre       = ["Crime", "Drama", "Thriller"]
      director    = "Jonathan Demme"
      rating      = 8.6
      description = "A young FBI cadet must receive the help of an incarcerated cannibal killer to catch another serial killer."
    },
    {
      title       = "Saving Private Ryan"
      year        = 1998
      genre       = ["Drama", "War"]
      director    = "Steven Spielberg"
      rating      = 8.6
      description = "Following the Normandy Landings, a group of soldiers go behind enemy lines to retrieve a paratrooper."
    },
    {
      title       = "The Green Mile"
      year        = 1999
      genre       = ["Crime", "Drama", "Fantasy"]
      director    = "Frank Darabont"
      rating      = 8.6
      description = "The lives of guards on Death Row are affected by one of their charges: a black man accused of murder."
    }
  ])

  content_type = "application/json"
  tags         = var.tags
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_loader" {
  name = "${var.project_name}-lambda-loader-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

# Lambda VPC Execution Policy
resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda_loader.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Lambda OpenSearch and S3 Access Policy
resource "aws_iam_role_policy" "lambda_opensearch" {
  name = "${var.project_name}-lambda-opensearch-policy"
  role = aws_iam_role.lambda_loader.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "es:ESHttpGet",
          "es:ESHttpPost",
          "es:ESHttpPut",
          "es:ESHttpDelete",
          "es:ESHttpHead"
        ]
        Resource = "${aws_opensearch_domain.main.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          module.s3_sample_data.s3_bucket_arn,
          "${module.s3_sample_data.s3_bucket_arn}/*"
        ]
      }
    ]
  })
}

# Create Lambda deployment package
data "archive_file" "lambda_package" {
  type        = "zip"
  output_path = "${path.module}/lambda_deployment.zip"

  source {
    content  = file("${path.module}/lambda/loader.py")
    filename = "loader.py"
  }
}

# Lambda Function
resource "aws_lambda_function" "data_loader" {
  filename         = data.archive_file.lambda_package.output_path
  function_name    = "${var.project_name}-data-loader"
  role             = aws_iam_role.lambda_loader.arn
  handler          = "loader.lambda_handler"
  source_code_hash = data.archive_file.lambda_package.output_base64sha256
  runtime          = "python3.11"
  timeout          = 300
  memory_size      = 512

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.opensearch.id]
  }

  environment {
    variables = {
      OPENSEARCH_ENDPOINT = aws_opensearch_domain.main.endpoint
      S3_BUCKET           = module.s3_sample_data.s3_bucket_id
      S3_KEY              = aws_s3_object.movies_data.key
      MASTER_USER         = var.master_user_name
      MASTER_PASSWORD     = var.master_user_password
    }
  }

  tags = var.tags

  depends_on = [
    aws_iam_role_policy_attachment.lambda_vpc,
    aws_iam_role_policy.lambda_opensearch,
    aws_opensearch_domain.main
  ]
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_lambda_function.data_loader.function_name}"
  retention_in_days = 7
  tags              = var.tags
}