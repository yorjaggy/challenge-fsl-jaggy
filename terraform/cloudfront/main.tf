locals {
  s3_origin_id = "fsl-s3-origin-${var.environment}"
}

resource "aws_cloudfront_origin_access_control" "oac_cloudfront" {
  name                              = "fsl-test-${var.environment}"
  description                       = "${var.environment} fsl Policy"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = var.s3_bucket_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.oac_cloudfront.id
    origin_id                = local.s3_origin_id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "FSL app ${var.environment}"
  default_root_object = "index.html"

  logging_config {
    include_cookies = false
    bucket          = "fsl-jaggy-dummy-mylogs.s3.amazonaws.com"
    prefix          = "${var.environment}-fsl-test"
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
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
      locations        = [] # Empty list when restriction_type is "none"
    }
  }

  tags = {
    Environment = var.environment
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}