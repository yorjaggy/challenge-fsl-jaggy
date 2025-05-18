output "distribution_id" {
  description = "The ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.s3_distribution.id
}

output "distribution_arn" {
  description = "The ARN of the CloudFront distribution"
  value       = aws_cloudfront_distribution.s3_distribution.arn
}

output "distribution_domain_name" {
  description = "The domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.s3_distribution.domain_name
}

output "origin_access_control_id" {
  description = "The ID of the CloudFront origin access control"
  value       = aws_cloudfront_origin_access_control.s3_origin_access_control.id
}