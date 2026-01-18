data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# S3 Buckets for Glue
module "s3_raw_data" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  bucket = "${var.project_name}-raw-data-${data.aws_caller_identity.current.account_id}"
<<<<<<< Updated upstream
=======
  
  force_destroy = var.force_destroy_buckets
>>>>>>> Stashed changes

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-raw-data"
      Environment = var.environment
    },
    var.tags
  )
}

module "s3_processed_data" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  bucket = "${var.project_name}-processed-data-${data.aws_caller_identity.current.account_id}"
<<<<<<< Updated upstream
=======
  
  force_destroy = var.force_destroy_buckets
>>>>>>> Stashed changes

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-processed-data"
      Environment = var.environment
    },
    var.tags
  )
}

module "s3_scripts" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  bucket = "${var.project_name}-scripts-${data.aws_caller_identity.current.account_id}"
<<<<<<< Updated upstream
=======
  
  force_destroy = var.force_destroy_buckets
>>>>>>> Stashed changes

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-scripts"
      Environment = var.environment
    },
    var.tags
  )
}

module "s3_temp" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  bucket = "${var.project_name}-temp-${data.aws_caller_identity.current.account_id}"
<<<<<<< Updated upstream
=======
  
  force_destroy = var.force_destroy_buckets
>>>>>>> Stashed changes

  lifecycle_rule = [
    {
      id      = "delete-old-files"
      enabled = true
      expiration = {
        days = 7
      }
    }
  ]

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-temp"
      Environment = var.environment
    },
    var.tags
  )
}

# Upload Glue scripts
resource "aws_s3_object" "etl_script" {
  bucket = module.s3_scripts.s3_bucket_id
  key    = "scripts/nyc_taxi_etl.py"
  source = "${path.module}/scripts/nyc_taxi_etl.py"
  etag   = filemd5("${path.module}/scripts/nyc_taxi_etl.py")

  tags = merge(var.common_tags, { Name = "nyc_taxi_etl.py" }, var.tags)
}

# IAM Role for Glue
data "aws_iam_policy_document" "glue_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "glue" {
  name               = "${var.project_name}-glue-role"
  assume_role_policy = data.aws_iam_policy_document.glue_assume_role.json

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-glue-role"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = aws_iam_role.glue.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

data "aws_iam_policy_document" "glue_s3_access" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]
    resources = [
      module.s3_raw_data.s3_bucket_arn,
      "${module.s3_raw_data.s3_bucket_arn}/*",
      module.s3_processed_data.s3_bucket_arn,
      "${module.s3_processed_data.s3_bucket_arn}/*",
      module.s3_scripts.s3_bucket_arn,
      "${module.s3_scripts.s3_bucket_arn}/*",
      module.s3_temp.s3_bucket_arn,
      "${module.s3_temp.s3_bucket_arn}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:/aws-glue/*"]
  }
}

resource "aws_iam_role_policy" "glue_s3_access" {
  name   = "${var.project_name}-glue-s3-access"
  role   = aws_iam_role.glue.id
  policy = data.aws_iam_policy_document.glue_s3_access.json
}

# Glue Database
resource "aws_glue_catalog_database" "this" {
  name        = "${var.project_name}_database"
  description = "Database for ${var.project_name}"

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-database"
      Environment = var.environment
    },
    var.tags
  )
}

# Glue Crawler for raw data
resource "aws_glue_crawler" "raw_data" {
  database_name = aws_glue_catalog_database.this.name
  name          = "${var.project_name}-raw-data-crawler"
  role          = aws_iam_role.glue.arn

  s3_target {
    path = "s3://${module.s3_raw_data.s3_bucket_id}/nyc-taxi/"
  }

  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "UPDATE_IN_DATABASE"
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableGroupingPolicy = "CombineCompatibleSchemas"
    }
  })

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-raw-data-crawler"
      Environment = var.environment
    },
    var.tags
  )
}

# Glue Job
resource "aws_glue_job" "etl" {
  name     = "${var.project_name}-nyc-taxi-etl"
  role_arn = aws_iam_role.glue.arn

  command {
    name            = "glueetl"
    script_location = "s3://${module.s3_scripts.s3_bucket_id}/${aws_s3_object.etl_script.key}"
    python_version  = var.python_version
  }

  glue_version      = var.glue_version
  max_retries       = var.max_retries
  timeout           = var.timeout_minutes
  worker_type       = var.worker_type
  number_of_workers = var.number_of_workers

  default_arguments = {
    "--job-language"                     = "python"
    "--job-bookmark-option"              = "job-bookmark-enable"
    "--enable-metrics"                   = var.enable_metrics ? "true" : "false"
    "--enable-spark-ui"                  = var.enable_spark_ui ? "true" : "false"
    "--spark-event-logs-path"            = "s3://${module.s3_temp.s3_bucket_id}/spark-logs/"
    "--enable-continuous-cloudwatch-log" = var.enable_continuous_log_filter ? "true" : "false"
    "--enable-continuous-log-filter"     = var.enable_continuous_log_filter ? "true" : "false"
    "--TempDir"                          = "s3://${module.s3_temp.s3_bucket_id}/temp/"
    "--SOURCE_BUCKET"                    = module.s3_raw_data.s3_bucket_id
    "--TARGET_BUCKET"                    = module.s3_processed_data.s3_bucket_id
    "--DATABASE_NAME"                    = aws_glue_catalog_database.this.name
  }

  execution_property {
    max_concurrent_runs = 1
  }

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-nyc-taxi-etl"
      Environment = var.environment
    },
    var.tags
  )

  depends_on = [
    aws_s3_object.etl_script,
    aws_glue_catalog_database.this
  ]
}

# Glue Trigger - Run daily at 2 AM UTC
resource "aws_glue_trigger" "daily" {
  name     = "${var.project_name}-daily-trigger"
  type     = "SCHEDULED"
  schedule = "cron(0 2 * * ? *)"
  enabled  = false # Set to true to enable automatic runs

  actions {
    job_name = aws_glue_job.etl.name
  }

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-daily-trigger"
      Environment = var.environment
    },
    var.tags
  )
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "glue_job" {
  name              = "/aws-glue/jobs/${aws_glue_job.etl.name}"
  retention_in_days = 7

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-glue-job-logs"
      Environment = var.environment
    },
    var.tags
  )
}

# Download and upload NYC taxi data
resource "null_resource" "download_nyc_data" {
  depends_on = [module.s3_raw_data]

  provisioner "local-exec" {
    command = <<-EOT
      # Download January 2024 data
      curl -L -o /tmp/yellow_tripdata_2024-01.parquet \
        https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2024-01.parquet

      # Upload to S3 raw data bucket
      aws s3 cp /tmp/yellow_tripdata_2024-01.parquet \
        s3://${module.s3_raw_data.s3_bucket_id}/nyc-taxi/year=2024/month=01/yellow_tripdata_2024-01.parquet

      # Cleanup
      rm -f /tmp/yellow_tripdata_2024-01.parquet
    EOT
  }

  triggers = {
    bucket_id = module.s3_raw_data.s3_bucket_id
  }
}

# Trigger crawler after data upload
resource "null_resource" "run_crawler" {
  depends_on = [null_resource.download_nyc_data, aws_glue_crawler.raw_data]

  provisioner "local-exec" {
    command = <<-EOT
      # Start the Glue crawler
      aws glue start-crawler --name ${aws_glue_crawler.raw_data.name}

      # Wait for crawler to complete (optional)
      echo "Crawler ${aws_glue_crawler.raw_data.name} started. Check AWS Console for status."
    EOT
  }

  triggers = {
    data_upload = null_resource.download_nyc_data.id
  }
}
