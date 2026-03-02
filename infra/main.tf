module "Dynamodb" {
    source = "./modules/dynamodb"
    table_name = var.dynamodb_table_name
}

module "s3" {
    source = "./modules/s3"
    project_name = var.project_name
}