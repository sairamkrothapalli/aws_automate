variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Main S3 bucket for ETL"
  default     = "aws--automate"
}