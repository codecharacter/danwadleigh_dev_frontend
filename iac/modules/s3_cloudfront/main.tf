###########################################################################
# Project: AWS Cloud Resume Challenge with DevOps mods
# App: CRC Frontend
# Module: S3 CDN
# Author: Dan Wadleigh (dan@codecharacter.dev)
#
# Note:
#   including TF/AWS doc links for educational CRC project assistance only
#
# Description: Create CloudFront distribution, OAC for S3, DNS record
#  - CloudFront: setup CF distribution
#    - efficient & secure content delivery from S3 bucket
#    - with Origin Access Control (OAC) for S3 Bucket containing website files
#  - S3 Bucket: containing website files
#  - S3 Bucket Policy: allow CF distribution to access S3 bucket objects
#  - AWS Certificate Manager: SSL certificate
###########################################################################

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter 
data "aws_ssm_parameter" "api_gateway_id" {
  name = "/app/danwadleigh_dev/api_gateway_id"
}

# Note: capturing API Gateway ID from CRC Backend
# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/apigatewayv2_api 
data "aws_apigatewayv2_api" "lambda" {
  api_id = data.aws_ssm_parameter.api_gateway_id.value
}

# AWS Docs: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-cache-policies.html
data "aws_cloudfront_cache_policy" "cdn_managed_caching_optimized_cache_policy" {
  name = "Managed-CachingOptimized"
}

# AWS Docs: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-cache-policies.html
data "aws_cloudfront_cache_policy" "cdn_managed_caching_disabled_cache_policy" {
  name = "Managed-CachingDisabled"
}

# AWS Docs: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-origin-request-policies.html
data "aws_cloudfront_origin_request_policy" "cdn_managed_all_viewer_except_host_header_origin_request_policy" {
  name = "Managed-AllViewerExceptHostHeader"
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_access_control
# AWS Docs: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html 
resource "aws_cloudfront_origin_access_control" "cloudfront_s3_oac" {
  name                              = "OAC for S3 Buckets"
  description                       = "Origin Access Control for Website Bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution 
#tfsec:ignore:aws-cloudfront-enable-logging
resource "aws_cloudfront_distribution" "website_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = var.index_document
  aliases             = [var.root_domain, "www.${var.root_domain}"]
  # TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution#web_acl_id
  web_acl_id = var.aws_wafv2_web_acl_arn

  origin {
    domain_name              = var.bucket_regional_domain_name
    origin_id                = "S3-${var.s3_bucket_id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.cloudfront_s3_oac.id
  }

  origin {
    domain_name = "${data.aws_apigatewayv2_api.lambda.api_id}.execute-api.${var.region}.amazonaws.com"
    origin_id   = "API-GW-${data.aws_apigatewayv2_api.lambda.api_id}"
    origin_path = "/prod"
    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = data.aws_cloudfront_cache_policy.cdn_managed_caching_optimized_cache_policy.id
    target_origin_id       = "S3-${var.s3_bucket_id}"
    viewer_protocol_policy = "redirect-to-https"
  }

  ordered_cache_behavior {
    path_pattern             = "/api/*"
    allowed_methods          = ["GET", "HEAD", "OPTIONS", "POST", "PUT", "PATCH", "DELETE"]
    cached_methods           = ["GET", "HEAD"]
    cache_policy_id          = data.aws_cloudfront_cache_policy.cdn_managed_caching_disabled_cache_policy.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.cdn_managed_all_viewer_except_host_header_origin_request_policy.id
    target_origin_id         = "API-GW-${data.aws_apigatewayv2_api.lambda.api_id}"
    viewer_protocol_policy   = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.ssl_cert_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy
resource "aws_s3_bucket_policy" "cloudfront_oac_policy" {
  bucket = var.s3_bucket_id

  policy = jsonencode({
    Version = "2008-10-17"
    Id      = "PolicyForCloudFrontPrivateContent"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "arn:aws:s3:::${var.s3_bucket_id}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.website_distribution.arn
          }
        }
      }
    ]
  })
}
