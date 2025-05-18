variable "bucket_name" {
  type        = string
  description = "Base name for the S3 bucket"
}

variable "environment" {
  type        = string
  description = "environment of rdicidr"
}

variable "build_path" {
  description = "build path of the static files"
  type        = string
  default     = "../build"
}