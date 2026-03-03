output "api_lambda_arn" {
  description = "ARN of the API Lambda function"
  value = aws_lambda_function.api.arn
}

output "api_lambda_invoke_arn" {
  description = "Invoke ARN of the API Lambda for API Gateway"
  value = aws_lambda_function.api.invoke_arn
}

# Function name is used to set API Gateway invoke permissions
output "api_lambda_function_name" {
  description = "Name of the API Lambda function"
  value       = aws_lambda_function.api.function_name
}