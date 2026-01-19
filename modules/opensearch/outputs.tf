output "domain_endpoint" {
  description = "OpenSearch domain endpoint (without https://)"
  value       = aws_opensearch_domain.main.endpoint
}

output "domain_id" {
  description = "Unique identifier for the OpenSearch domain"
  value       = aws_opensearch_domain.main.domain_id
}

output "domain_arn" {
  description = "ARN of the OpenSearch domain"
  value       = aws_opensearch_domain.main.arn
}

output "domain_name" {
  description = "Name of the OpenSearch domain"
  value       = aws_opensearch_domain.main.domain_name
}

output "security_group_id" {
  description = "Security group ID for OpenSearch"
  value       = aws_security_group.opensearch.id
}

output "data_bucket_id" {
  description = "S3 bucket ID containing sample data"
  value       = module.s3_sample_data.s3_bucket_id
}

output "data_bucket_arn" {
  description = "S3 bucket ARN containing sample data"
  value       = module.s3_sample_data.s3_bucket_arn
}

output "dashboards_endpoint" {
  description = "OpenSearch Dashboards (Kibana) endpoint URL"
  value       = "https://${aws_opensearch_domain.main.endpoint}/_dashboards"
}

output "lambda_function_name" {
  description = "Name of the Lambda function that loads sample data"
  value       = aws_lambda_function.data_loader.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function that loads sample data"
  value       = aws_lambda_function.data_loader.arn
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch log group name for OpenSearch logs"
  value       = aws_cloudwatch_log_group.opensearch.name
}
