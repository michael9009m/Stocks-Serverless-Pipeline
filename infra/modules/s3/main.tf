#Create s3 bucket

resource "aws_s3_bucket" "frontend"{
    bucket = "${var.project_name}-frontend"

    tags = {
        Project = "stocks-pipeline"
    }
}

#Enable static website hosting, allows s3 bucket to serve html
resource "aws_s3_bucket_website_configuration" "frontend" {
    bucket = aws_s3_bucket.frontend.id

    index_document {
        suffix = "index.html"
    }
}

#turn OFF auto public acccess blockers
resource "aws_s3_bucket_public_access_block" "frontend" {
    bucket = aws_s3_bucket.frontend.id

    block_public_acls = false
    block_public_policy = false
    ignore_public_acls = false
    restrict_public_buckets = false
}

#allows anyone to read files from bucket

resource "aws_s3_bucket_policy" "frontend" {
    bucket = aws_s3_bucket.frontend.id 

    depends_on = [aws_s3_bucket_public_access_block.frontend]

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Sid = "PublicReadGetObject"
                Effect = "Allow"
                Principal = "*"
                Action = "s3:GetObject"
                Resource = "${aws_s3_bucket.frontend.arn}/*"
            }
        ]
    })
}