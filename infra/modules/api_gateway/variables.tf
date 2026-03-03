
variable "project_name" {
  description = "Project name used for naming resources"
  type        = string
}


variable "api_lambda_invoke_arn" {
  description = "Invoke ARN of the API Lambda function"
  type        = string
}

variable "api_lambda_function_name" {
  description = "Name of the API Lambda function"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}