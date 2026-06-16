# Define your locals block with metadata
locals {
  test_metadata = {
    api_key  = "XVGYUhyauety23899ajjjagGGGG"
    username = "testuser"
    password = "testpassword123"
  }
}

# Provider configuration
provider "aws" {
  region = "us-east-1"
}

# S3 Bucket Resource
resource "aws_s3_bucket" "example_bucket" {
  bucket = "my-unique-tf-test-bucket-12345"

  # Applying the locals to tags
  tags = {
    Name     = "MetadataTestBucket"
    API_Key  = local.test_metadata.api_key
    User     = local.test_metadata.username
    Password = local.test_metadata.password
  }
}

# Optional: Manage Public Access Block for security
resource "aws_s3_bucket_public_access_block" "example_access" {
  bucket = aws_s3_bucket.example_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
