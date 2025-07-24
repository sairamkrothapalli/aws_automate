resource "aws_s3_bucket" "etl_bucket" {
  bucket = var.bucket_name

  tags = {
    Name        = "ETL Bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_public_access_block" "block_public" {
  bucket = aws_s3_bucket.etl_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Optional: Create folder-like prefixes in S3
resource "aws_s3_object" "folders" {
  for_each = toset(["raw/", "curated/", "logs/"])

  bucket = aws_s3_bucket.etl_bucket.id
  key    = each.key
 source = "empty.txt"
etag   = filemd5("empty.txt")
}