###########################################################################
# Project: AWS Cloud Resume Challenge with DevOps mods
# App: CRC Frontend
# Module: Terraform State Remote Backend
# Author: Dan Wadleigh (dan@codecharacter.dev)
#
# Note:
#   including TF/AWS doc links for educational CRC project assistance only
#
# Description: Create remote backend for TF state and locking
#  - IAM User: for Terraform with permissions to manage infra
#  - IAM Policy: for Terraform user permissions
#  - S3 Bucket: for Terraform statefile and versioning infra state
#  - S3 Bucket Policy: specify S3 bucket permissions allowing TF user
#  - DynamoDB Table: for state locking when statefile in use
###########################################################################

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user 
resource "aws_iam_user" "terraform_user" {
  name = var.iam_user_name
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user_policy_attachment 
resource "aws_iam_user_policy_attachment" "admin_policy_attachment" {
  policy_arn = var.tf_fe_policy_arn
  user       = aws_iam_user.terraform_user.id
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket
resource "aws_s3_bucket" "terraform_state_bucket" {
  bucket = var.bucket_name

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = var.bucket_name
  }
}

# TF Docs: # TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket 
#tfsec:ignore:aws-s3-enable-bucket-logging
resource "aws_s3_bucket" "log_bucket_tf_state" {
  bucket = "logging-tf-state-fe"
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging
resource "aws_s3_bucket_logging" "logging_tf_state" {
  bucket = aws_s3_bucket.terraform_state_bucket.id

  target_bucket = aws_s3_bucket.log_bucket_tf_state.id
  target_prefix = "log-fe/"
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key 
resource "aws_kms_key" "s3_tf_state_kms" {
  description         = "s3_tf_state_fe_kms"
  enable_key_rotation = true
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration
resource "aws_s3_bucket_server_side_encryption_configuration" "s3_remotefe_encryption" {
  bucket = aws_s3_bucket.terraform_state_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_tf_state_kms.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block 
resource "aws_s3_bucket_public_access_block" "tf_state_bucket_public_access_block" {
  bucket                  = aws_s3_bucket.terraform_state_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning
resource "aws_s3_bucket_versioning" "versioning_enabled" {
  bucket = aws_s3_bucket.terraform_state_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy 
resource "aws_s3_bucket_policy" "s3_bucket_policy" {
  bucket = aws_s3_bucket.terraform_state_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "s3:ListBucket",
        Resource = aws_s3_bucket.terraform_state_bucket.arn,
        Principal = {
          AWS = aws_iam_user.terraform_user.arn
        }
      },
      {
        Effect   = "Allow",
        Action   = ["s3:GetObject", "s3:PutObject"],
        Resource = "${aws_s3_bucket.terraform_state_bucket.arn}/*",
        Principal = {
          AWS = aws_iam_user.terraform_user.arn
        }
      }
    ]
  })
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table 
resource "aws_dynamodb_table" "state_lock_table" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  lifecycle {
    prevent_destroy = true
  }

  point_in_time_recovery {
    enabled = true
  }

  deletion_protection_enabled = true

  #tfsec:ignore:aws-dynamodb-table-customer-key
  server_side_encryption {
    enabled = true
  }

  tags = {
    Name = var.table_name
  }
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key 
resource "aws_kms_key" "s3_tf_state_logging_kms" {
  description         = "s3_tf_state_logging_fe_kms"
  enable_key_rotation = true
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration
resource "aws_s3_bucket_server_side_encryption_configuration" "s3_remotefe_logging_encryption" {
  bucket = aws_s3_bucket.log_bucket_tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_tf_state_logging_kms.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block 
resource "aws_s3_bucket_public_access_block" "tf_state_logging_bucket_public_access_block" {
  bucket                  = aws_s3_bucket.log_bucket_tf_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning 
resource "aws_s3_bucket_versioning" "versioning_logging_enabled" {
  bucket = aws_s3_bucket.log_bucket_tf_state.id

  versioning_configuration {
    status = "Enabled"
  }
}