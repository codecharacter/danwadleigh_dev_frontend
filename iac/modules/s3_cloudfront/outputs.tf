output "cloudfront_distribution_arn" {
  description = "ARN of CloudFront Distribution"
  value       = aws_cloudfront_distribution.website_distribution.arn
}

output "cloudfront_distribution_domain_name" {
  description = "Domain name of CloudFront Distribution"
  value       = aws_cloudfront_distribution.website_distribution.domain_name
}

output "cloudfront_distribution_hosted_zone_id" {
  description = "Hosted Zone ID of CloudFront Distribution"
  value       = aws_cloudfront_distribution.website_distribution.hosted_zone_id
}

output "cloudfront_distribution_id" {
  description = "ID of CloudFront Distribution"
  value       = aws_cloudfront_distribution.website_distribution.id
}

output "origin_access_control_id" {
  description = "Origin Access Control ID for CloudFront Distribution"
  value       = aws_cloudfront_origin_access_control.cloudfront_s3_oac.id
}
