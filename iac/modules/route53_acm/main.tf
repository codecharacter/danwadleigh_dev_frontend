###########################################################################
# Project: AWS Cloud Resume Challenge with DevOps mods
# App: CRC Frontend
# Module: DNS + SSL
# Author: Dan Wadleigh (dan@codecharacter.dev)
#
# Note:
#   including TF/AWS doc links for educational CRC project assistance only
#
# Description: Create DNS zones/records and SSL certificate with validations
#  - Route 53: DNS management (hosted zone, records)
#    - alias CF distribution endpoint to root/www domain
#  - AWS Certificate Manager: handling SSL certificates + validation
#    - sets up secure, encrypted connections to website
#    - ensures SSL cert is correctly configured and validated
###########################################################################

# Get Route53 Hosted Zone info
# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone 
data "aws_route53_zone" "dns_zone" {
  name         = var.root_domain
  private_zone = false
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate 
resource "aws_acm_certificate" "ssl_certificate" {
  domain_name               = var.root_domain
  subject_alternative_names = ["*.${var.root_domain}"]
  validation_method         = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record 
resource "aws_route53_record" "dns_validation" {
  allow_overwrite = true
  name            = tolist(aws_acm_certificate.ssl_certificate.domain_validation_options)[0].resource_record_name
  records         = [tolist(aws_acm_certificate.ssl_certificate.domain_validation_options)[0].resource_record_value]
  type            = tolist(aws_acm_certificate.ssl_certificate.domain_validation_options)[0].resource_record_type
  zone_id         = data.aws_route53_zone.dns_zone.zone_id
  ttl             = var.dns_record_ttl
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation 
resource "aws_acm_certificate_validation" "ssl_validation" {
  certificate_arn         = aws_acm_certificate.ssl_certificate.arn
  validation_record_fqdns = [aws_route53_record.dns_validation.fqdn]
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record
resource "aws_route53_record" "website_alias_record" {
  zone_id = data.aws_route53_zone.dns_zone.zone_id
  name    = var.root_domain
  type    = "A"

  alias {
    name                   = var.cloudfront_distribution_domain_name
    zone_id                = var.cloudfront_distribution_hosted_zone_id
    evaluate_target_health = true
  }
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record
resource "aws_route53_record" "website_alias_record_www" {
  zone_id = data.aws_route53_zone.dns_zone.zone_id
  name    = "www"
  type    = "A"

  alias {
    name                   = var.cloudfront_distribution_domain_name
    zone_id                = var.cloudfront_distribution_hosted_zone_id
    evaluate_target_health = true
  }
}

# Create custom domain name for API Gateway endpoint
# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_domain_name 
resource "aws_apigatewayv2_domain_name" "api" {
  domain_name = var.root_domain

  domain_name_configuration {
    certificate_arn = aws_acm_certificate.ssl_certificate.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }

  depends_on = [aws_acm_certificate_validation.ssl_validation]
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter 
data "aws_ssm_parameter" "api_gateway_id" {
  name = "/app/danwadleigh_dev/api_gateway_id"
}

# Note: capturing API Gateway ID from CRC Backend
# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/apigatewayv2_api 
data "aws_apigatewayv2_api" "lambda" {
  api_id = data.aws_ssm_parameter.api_gateway_id.value
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_api_mapping 
resource "aws_apigatewayv2_api_mapping" "api" {
  api_id          = data.aws_apigatewayv2_api.lambda.api_id # Backend
  domain_name     = aws_apigatewayv2_domain_name.api.id
  stage           = var.http_api_stage_name
  api_mapping_key = "api"
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key
resource "aws_kms_key" "domaindnssec" {
  customer_master_key_spec = "ECC_NIST_P256"
  deletion_window_in_days  = 7
  key_usage                = "SIGN_VERIFY"
  policy = jsonencode({
    Statement = [
      {
        Action = [
          "kms:DescribeKey",
          "kms:GetPublicKey",
          "kms:Sign",
        ],
        Effect = "Allow"
        Principal = {
          Service = "dnssec-route53.amazonaws.com"
        }
        Sid      = "Allow Route 53 DNSSEC Service",
        Resource = "*"
      },
      {
        Action = "kms:CreateGrant",
        Effect = "Allow"
        Principal = {
          Service = "dnssec-route53.amazonaws.com"
        }
        Sid      = "Allow Route 53 DNSSEC Service to CreateGrant",
        Resource = "*"
        Condition = {
          Bool = {
            "kms:GrantIsForAWSResource" = "true"
          }
        }
      },
      {
        Action = "kms:*"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Resource = "*"
        Sid      = "IAM User Permissions"
      },
    ]
    Version = "2012-10-17"
  })
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_key_signing_key
resource "aws_route53_key_signing_key" "dnssecksk" {
  name                       = var.root_domain
  hosted_zone_id             = data.aws_route53_zone.dns_zone.id
  key_management_service_arn = aws_kms_key.domaindnssec.arn
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_hosted_zone_dnssec
resource "aws_route53_hosted_zone_dnssec" "dns_zone_dnssec" {
  depends_on = [
    aws_route53_key_signing_key.dnssecksk
  ]
  hosted_zone_id = aws_route53_key_signing_key.dnssecksk.hosted_zone_id
}