output "glue_database_name" {
  description = "Name of the Glue database"
  value       = aws_glue_catalog_database.this.name
}

output "glue_job_name" {
  description = "Name of the Glue ETL job"
  value       = aws_glue_job.etl.name
}

output "glue_crawler_name" {
  description = "Name of the Glue crawler"
  value       = aws_glue_crawler.raw_data.name
}

output "raw_data_bucket" {
  description = "S3 bucket for raw data"
  value       = module.s3_raw_data.s3_bucket_id
}

output "processed_data_bucket" {
  description = "S3 bucket for processed data"
  value       = module.s3_processed_data.s3_bucket_id
}

output "scripts_bucket" {
  description = "S3 bucket for Glue scripts"
  value       = module.s3_scripts.s3_bucket_id
}

output "temp_bucket" {
  description = "S3 bucket for temporary files"
  value       = module.s3_temp.s3_bucket_id
}

output "glue_role_arn" {
  description = "ARN of the Glue IAM role"
  value       = aws_iam_role.glue.arn
}

output "glue_trigger_name" {
  description = "Name of the Glue trigger"
  value       = aws_glue_trigger.daily.name
}