# The public URL of your frontend website
# This is the link you submit as your live frontend deliverable
output "website_url" {
  description = "S3 static website URL"
  value       = module.s3.website_url
}

# The public URL of your API endpoint
# This is what your frontend will call to get stock data
output "api_url" {
  description = "API Gateway endpoint URL"
  value       = module.api_gateway.api_url
}

# The DynamoDB table name
# Useful to confirm the table was created correctly
output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = module.dynamodb.table_name
}