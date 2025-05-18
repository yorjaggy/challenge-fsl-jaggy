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

resource "aws_s3_bucket" "s3_bucket" {
  bucket = var.bucket_name

  tags = {
    Name        = var.bucket_name
    Environment = var.environment
  }
}

resource "aws_s3_bucket_ownership_controls" "s3_bucket_ownership_controls_rdcicdr" {
  bucket = aws_s3_bucket.s3_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "example" {
  depends_on = [aws_s3_bucket_ownership_controls.s3_bucket_ownership_controls_rdcicdr]

  bucket = aws_s3_bucket.s3_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_website_configuration" "s3_bucket_website_conf" {
  bucket = aws_s3_bucket.s3_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
  bucket = aws_s3_bucket.s3_bucket.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : {
      "Sid" : "AllowCloudFrontServicePrincipalReadOnly",
      "Effect" : "Allow",
      "Principal" : {
        "Service" : "cloudfront.amazonaws.com"
      },
      "Action" : "s3:GetObject",
      "Resource" : "${aws_s3_bucket.s3_bucket.arn}/*",
      "Condition" : {
        "StringEquals" : {
          "AWS:SourceArn" : "${aws_cloudfront_distribution.s3_distribution.arn}"
        }
      }
    }
  })
}

resource "aws_s3_object" "object" {
  bucket = aws_s3_bucket.s3_bucket.id

  for_each = fileset("../build", "**/*.*")

  key    = each.value
  source = "../build/${each.value}"

  content_type = lookup({
    "html" = "text/html"
    "css"  = "text/css"
    "js"   = "application/js"
    "json" = "application/json"
  }, split(".", each.value)[length(split(".", each.value)) - 1], "application/octet-stream")
}

# AWS Cloudfront
locals {
  s3_origin_id = "fsl-s3-origin"
}

resource "aws_cloudfront_origin_access_control" "oac_cloudfront" {
  name                              = "fsl-test"
  description                       = "fsl Policy"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.s3_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.oac_cloudfront.id
    origin_id                = local.s3_origin_id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "FSL app"
  default_root_object = "index.html"

  logging_config {
    include_cookies = false
    bucket          = "fsl-jaggy-dummy-mylogs.s3.amazonaws.com"
    prefix          = "fsl-test"
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  tags = {
    Environment = var.environment
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}