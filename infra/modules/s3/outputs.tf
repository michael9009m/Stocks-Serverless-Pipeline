output "website_url" {
    description = "S3 static website url"
    value = aws_s3_bucket_website_configuration.frontend.website_endpoint
}
output "bucket_name" {
    description = "S3 bucket name"
    value = aws_s3_bucket.frontend.id
}