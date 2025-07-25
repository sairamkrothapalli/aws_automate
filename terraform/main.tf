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
  for_each = toset(["raw/", "curated/", "scripts/"])  # changed from logs/ to scripts/

  bucket = aws_s3_bucket.etl_bucket.id
  key    = each.key
  source = "empty.txt"
  etag   = filemd5("empty.txt")
}

# ------------------------------------------
# 🔐 IAM Role for AWS Glue
# ------------------------------------------
resource "aws_iam_role" "glue_role" {
  name = "glue_service_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "glue.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# ✅ Attach Glue Service Policy
resource "aws_iam_role_policy_attachment" "glue_policy_attach" {
  role       = aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# ✅ Add S3 Full Access for Reading/Writing Scripts & Data
resource "aws_iam_role_policy" "glue_s3_policy" {
  name = "glue-s3-access"
  role = aws_iam_role.glue_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::aws--automate",
          "arn:aws:s3:::aws--automate/*"
        ]
      }
    ]
  })
}

# ------------------------------------------
# 🛠️ AWS Glue Job
# ------------------------------------------
resource "aws_glue_job" "insurance_etl_job" {
  name     = "insurance-etl-job"
  role_arn = aws_iam_role.glue_role.arn

  command {
    name            = "glueetl"
    script_location = "s3://aws--automate/scripts/glue_transform.py"
    python_version  = "3"
  }

  glue_version      = "4.0"
  number_of_workers = 2
  worker_type       = "G.1X"

  execution_property {
    max_concurrent_runs = 1
  }

  timeout     = 10
  description = "Glue ETL job to process insurance claims data"
}