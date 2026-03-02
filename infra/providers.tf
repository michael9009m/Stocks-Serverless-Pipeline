terraform{
    required_providers{
        aws = {
            source = "hashicorp/aws"
            version = "~> 5.0"
        }
    }
 

    backend "s3"{
        bucket = "stocks-pipeline-tfstate-michael"
        key = "stocks-pipeline/terraform.tfstate"
        region = "us-west-2"
    }
}

provider "aws"{
    region = var.aws_region
}