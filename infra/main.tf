module "dynamodb" {
    source = "./modules/dynamodb"
    table_name = var.dynamodb_table_name
}

module "s3" {
    source = "./modules/s3"
    project_name = var.project_name
}

module "lambda" {
    source = "./modules/lambda"
    project_name = var.project_name
    dynamodb_table_name = var.dynamodb_table_name
    dynamodb_table_arn = module.dynamodb.table_arn
    secret_arn = "arn:aws:secretsmanager:us-west-2:631534401457:secret:stocks-pipeline/massive-api-key-M0ALCy"
    secret_name = "stocks-pipeline/massive-api-key"
    ingestion_zip_path = "../lambdas/ingestion/ingestion.zip"
    api_zip_path = "../lambdas/api/api.zip"
}

module "api_gateway" {
  source                   = "./modules/api_gateway"
  project_name             = var.project_name
  region                   = var.aws_region
  api_lambda_invoke_arn    = module.lambda.api_lambda_invoke_arn
  api_lambda_function_name = module.lambda.api_lambda_function_name
}