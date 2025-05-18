# In this file put all the logic to crete the proper infraestructure
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.98.0"
    }
  }

  backend "s3" {
    bucket = "iac-fsl-jaggy-test"
    region = "us-east-1"
  }
}

# Add the resources relatedo to the provider

# AWS S3

module "s3" {
  source = "./modules/s3"

  bucket_name                 = "${var.environment}-${var.bucket_name}"
  environment                 = var.environment
  cloudfront_distribution_arn = module.cloudfront.distribution_arn
  build_path                  = var.build_path
}

# AWS Cloudfront
module "cloudfront" {
  source = "./modules/cloudfront"

  environment           = var.environment
  s3_bucket_domain_name = module.s3.bucket_regional_domain_name
}