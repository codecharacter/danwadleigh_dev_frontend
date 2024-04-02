#############################################################################################
# Project: AWS Cloud Resume Challenge with DevOps mods
# App: CRC Frontend
# Author: Dan Wadleigh (dan@codecharacter.dev)
# Description: 
#  - serverless frontend that integrates with backend 
#  - website built with HTML, CSS, JavaScript
#  - hosted statically on S3
#  - delivered securely via CloudFront with ACM SSL certificate
#  - dns configured via Route 53
#  - monitoring and alerting solution (CloudWatch, SNS, PagerDuty, Slack)
#  - IaC (Terraform), CI/CD (GitHub Actions) and Testing (Cypress)
# Note:
#   including TF/AWS doc links for educational project assistance
# Resources:
#   Project Article: https://codecharacter.dev/semper-gumby-a-marines-journey-in-the-cloud/ 
#   Resume Site: https://DanWadleigh.dev/ 
#   LinkedIn: https://linkedin.com/in/danwadleigh
# 
#############################################################################################
module "backend" {
  source           = "./modules/remote_backend"
  bucket_name      = var.bucket_name
  iam_user_name    = var.iam_user_name
  table_name       = var.table_name
  tf_fe_policy_arn = module.iam.tf_fe_policy_arn
}

module "cloudfront" {
  source                      = "./modules/s3_cloudfront"
  aws_wafv2_web_acl_arn       = module.waf.aws_wafv2_web_acl_arn
  bucket_regional_domain_name = module.s3_website.bucket_regional_domain_name
  index_document              = var.index_document
  region                      = var.region
  root_domain                 = var.root_domain
  s3_bucket_id                = module.s3_website.s3_bucket_id
  ssl_cert_arn                = module.dns_acm.ssl_cert_arn
}

module "dns_acm" {
  source                                 = "./modules/route53_acm"
  cloudfront_distribution_domain_name    = module.cloudfront.cloudfront_distribution_domain_name
  cloudfront_distribution_hosted_zone_id = module.cloudfront.cloudfront_distribution_hosted_zone_id
  dns_record_ttl                         = var.dns_record_ttl
  http_api_stage_name                    = var.http_api_stage_name
  root_domain                            = var.root_domain
}

module "iam" {
  source                        = "./modules/iam"
  bucket_name                   = var.bucket_name
  bucket_logging_fe_name        = var.bucket_logging_fe_name
  cloudfront_distribution_id    = module.cloudfront.cloudfront_distribution_id
  counter_table_name            = var.counter_table_name
  github_actions_role_fe_policy = var.github_actions_role_fe_policy
  github_actions_url            = var.github_actions_url
  iam_role_name                 = var.iam_role_name
  iam_user_name                 = var.iam_user_name
  origin_access_control_id      = module.cloudfront.origin_access_control_id
  region                        = var.region
  root_domain                   = var.root_domain
  route53_zone_id               = module.dns_acm.route53_zone_id
  s3_website_log_bucket_name    = module.s3_website.s3_website_log_bucket_name
  table_name                    = var.table_name
  terraform_frontend_policy     = var.terraform_frontend_policy
}

module "s3_website" {
  source                     = "./modules/s3_website"
  force_destroy              = var.force_destroy
  index_document             = var.index_document
  region                     = var.region
  versioning_enabled         = var.versioning_enabled
  website_bucket             = var.website_bucket
  cloudfront_distribution_id = module.cloudfront.cloudfront_distribution_id
}

module "waf" {
  source = "./modules/waf"
  region = var.region
}