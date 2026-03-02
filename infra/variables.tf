variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-west-2"
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  type        = string
  default     = "stock-movers"
}

variable "project_name" {
  description = "Project name used for naming resources"
  type        = string
  default     = "stocks-pipeline"
}