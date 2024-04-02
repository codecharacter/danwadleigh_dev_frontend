###########################################################################
# Project: AWS Cloud Resume Challenge with DevOps mods
# App: CRC Frontend
# Module: S3 Static Website
# Author: Dan Wadleigh (dan@codecharacter.dev)
#
# Note:
#   including TF/AWS doc links for educational CRC project assistance only
#
# Description: Create S3 bucket and configure for static website
#  - S3 Bucket: hosting static website (HTML, CSS, JS files)
#  - S3 Bucket Public Access: configure accessibility of website to everyone
#  - S3 Bucket Policy: granting public read access to objects in S3 bucket
#    - enhances visibility of website content
###########################################################################

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity
data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket
resource "aws_s3_bucket" "website_bucket" {
  bucket        = var.website_bucket
  force_destroy = var.force_destroy

  tags = {
    Name = "Website bucket for ${var.website_bucket}"
  }
}

# TF Docs: # TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket 
#tfsec:ignore:aws-s3-enable-bucket-logging
resource "aws_s3_bucket" "log_bucket_website" {
  bucket = "logging-website-resume-dw"
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging
resource "aws_s3_bucket_logging" "logging_website" {
  bucket = aws_s3_bucket.website_bucket.id

  target_bucket = aws_s3_bucket.log_bucket_website.id
  target_prefix = "log/"
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key 
resource "aws_kms_key" "s3_website_kms" {
  description         = "s3_website_kms"
  enable_key_rotation = true
  policy = jsonencode({
    "Id" : "AllowCloudFront",
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "Enable IAM User Permissions",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::814913991817:root"
        },
        "Action" : "kms:*",
        "Resource" : "*"
      },
      {
        "Sid" : "Allow use of the key",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : [
            "cloudfront.amazonaws.com"
          ]
        },
        "Action" : [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringEquals" : {
            "aws:SourceArn" : "arn:aws:cloudfront::${local.account_id}:distribution/${var.cloudfront_distribution_id}"
          }
        }
      }
    ]
  })
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration
resource "aws_s3_bucket_server_side_encryption_configuration" "s3_website_encryption" {
  bucket = aws_s3_bucket.website_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_website_kms.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning
resource "aws_s3_bucket_versioning" "website_versioning" {
  bucket = aws_s3_bucket.website_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_website_configuration
resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = aws_s3_bucket.website_bucket.id

  index_document {
    suffix = var.index_document
  }
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block
#tfsec:ignore:aws-s3-block-public-acls tfsec:ignore:aws-s3-block-public-policy tfsec:ignore:aws-s3-ignore-public-acls tfsec:ignore:aws-s3-no-public-buckets
resource "aws_s3_bucket_public_access_block" "website_bucket_allow_public_access" {
  bucket = aws_s3_bucket.website_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy
resource "aws_s3_bucket_policy" "website_policy" {
  bucket = aws_s3_bucket.website_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = ["s3:GetObject"],
        Effect    = "Allow",
        Resource  = ["${aws_s3_bucket.website_bucket.arn}/*"],
        Principal = "*"
      },
    ]
  })
  # applied only AFTER public access block settings are configured to remove access errors
  depends_on = [aws_s3_bucket_public_access_block.website_bucket_allow_public_access]
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key 
resource "aws_kms_key" "s3_website_logging_kms" {
  description         = "s3_website_logging_kms"
  enable_key_rotation = true
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration
resource "aws_s3_bucket_server_side_encryption_configuration" "s3_website_logging_encryption" {
  bucket = aws_s3_bucket.log_bucket_website.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_website_logging_kms.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block 
resource "aws_s3_bucket_public_access_block" "website_logging_bucket_public_access_block" {
  bucket                  = aws_s3_bucket.log_bucket_website.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning 
resource "aws_s3_bucket_versioning" "versioning_logging_enabled" {
  bucket = aws_s3_bucket.log_bucket_website.id

  versioning_configuration {
    status = "Enabled"
  }
}