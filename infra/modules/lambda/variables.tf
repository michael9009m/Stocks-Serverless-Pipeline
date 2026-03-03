variable "project_name" {
  description = "Project name used for naming resources"
  type        = string
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  type        = string
}

variable "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table for IAM permissions"
  type        = string
}

variable "secret_arn" {
  description = "ARN of the Secrets Manager secret containing the Massive API key"
  type        = string
}

variable "secret_name" {
  description = "Name of the Secrets Manager secret"
  type        = string
}

variable "ingestion_zip_path" {
  description = "Path to the zipped ingestion Lambda function code"
  type        = string
}

variable "api_zip_path" {
  description = "Path to the zipped API Lambda function code"
  type        = string
}