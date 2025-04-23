

provider "aws" {
  region = "us-east-1"
  alias  = "backend"
}

data "aws_s3_bucket" "terraform_state" {
  provider = aws.backend
  bucket   = "ec2-transformation-terraform-state"
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  provider = aws.backend
  bucket   = data.aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  provider = aws.backend
  bucket   = data.aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

data "aws_dynamodb_table" "terraform_locks" {
  provider = aws.backend
  name     = "ec2-transformation-terraform-locks"
}

output "backend_s3_bucket_name" {
  value       = data.aws_s3_bucket.terraform_state.bucket
  description = "The name of the S3 bucket for Terraform state"
}

output "backend_dynamodb_table_name" {
  value       = data.aws_dynamodb_table.terraform_locks.name
  description = "The name of the DynamoDB table for Terraform locks"
}
