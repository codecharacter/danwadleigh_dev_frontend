output "aws_wafv2_web_acl_arn" {
  description = "AWS WAFv2 Web ACL ARN"
  value       = module.waf.aws_wafv2_web_acl_arn
}

output "cloudfront_distribution_domain_name" {
  description = "Domain name of CloudFront Distribution"
  value       = module.cloudfront.cloudfront_distribution_domain_name
}

output "cloudfront_distribution_hosted_zone_id" {
  description = "Hosted Zone ID of CloudFront Distribution"
  value       = module.cloudfront.cloudfront_distribution_hosted_zone_id
}

output "cloudfront_distribution_id" {
  description = "CloudFront Distribution ID"
  value       = module.cloudfront.cloudfront_distribution_id
}

output "gha_role_fe_policy_arn" {
  description = "GitHub Actions role IAM policy arn"
  value       = module.iam.gha_role_fe_policy_arn
}

output "iam_user_name" {
  description = "IAM User for Frontend Terraform"
  value       = module.backend.iam_user_arn
}

output "origin_access_control_id" {
  description = "Origin Access Control ID for CloudFront Distribution"
  value       = module.cloudfront.origin_access_control_id
}

output "route53_zone_id" {
  description = "ID of Route53 Zone"
  value       = module.dns_acm.route53_zone_id
}

output "s3_bucket_id" {
  description = "ID of S3 Bucket"
  value       = module.s3_website.s3_bucket_id
}

output "s3_website_log_bucket_name" {
  description = "S3 Website Log Bucket Name"
  value       = module.s3_website.s3_website_log_bucket_name
}

output "s3_website_url" {
  description = "S3 URL of Website"
  value       = module.s3_website.s3_website_url
}

output "ssl_cert_arn" {
  description = "ARN of SSL Certificate"
  value       = module.dns_acm.ssl_cert_arn
}

output "tf_fe_policy_arn" {
  description = "terraform_frontend user IAM policy arn"
  value       = module.iam.tf_fe_policy_arn
}
