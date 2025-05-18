variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "s3_bucket_domain_name" {
  description = "Domain name of the S3 bucket"
  type        = string
}