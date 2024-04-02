output "bucket_regional_domain_name" {
  description = "Regional domain name of S3 bucket"
  value       = aws_s3_bucket.website_bucket.bucket_regional_domain_name
}

output "s3_bucket_id" {
  description = "ID of S3 Bucket"
  value       = aws_s3_bucket.website_bucket.id
}

output "s3_website_log_bucket_name" {
  description = "S3 Website Log Bucket Name"
  value       = aws_s3_bucket.log_bucket_website.id
}

output "s3_website_url" {
  description = "URL of Website"
  value       = "http://${aws_s3_bucket.website_bucket.bucket}.s3-website-${var.region}.amazonaws.com"
}
