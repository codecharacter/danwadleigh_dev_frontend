###########################################################################
# Project: AWS Cloud Resume Challenge with DevOps mods
# App: CRC Frontend
# Module: IAM
# Author: Dan Wadleigh (dan@codecharacter.dev)
#
# Note:
#   including TF/AWS doc links for educational CRC project assistance only
#
# Description: Create IAM policy for Terraform Frontend user
#  - IAM Access Advisor: identified allowed management actions for services
#  - IAM Policy: built based on actions accessed by user
#  - Note: some actions/resources identified during tf apply
###########################################################################

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity
data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy
resource "aws_iam_policy" "tf_fe_policy" {
  name        = "terraform_frontend_policy"
  path        = "/"
  description = "IAM Policy actions for terraform_frontend user"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:PutObject",
          "s3:GetObject",
          "s3:GetBucketPublicAccessBlock",
          "s3:ListBucket",
          "s3:GetLifecycleConfiguration",
          "s3:PutBucketPublicAccessBlock",
          "s3:GetBucketWebsite",
          "s3:GetBucketLogging",
          "s3:CreateBucket",
          "s3:GetAccelerateConfiguration",
          "s3:GetBucketVersioning",
          "s3:GetBucketAcl",
          "s3:GetBucketPolicy",
          "s3:GetBucketObjectLockConfiguration",
          "s3:GetEncryptionConfiguration",
          "s3:PutBucketWebsite",
          "s3:GetBucketRequestPayment",
          "s3:GetBucketCORS",
          "s3:PutBucketPolicy",
          "s3:GetBucketLocation",
          "s3:PutBucketVersioning"
        ],
        "Resource" : [
          "arn:aws:s3:::${var.bucket_name}",
          "arn:aws:s3:::${var.bucket_name}/*",
          "arn:aws:s3:::${var.root_domain}",
          "arn:aws:s3:::${var.root_domain}/*"
        ],
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "cloudfront:GetDistribution",
          "cloudfront:GetOriginAccessControl",
          "cloudfront:CreateDistribution",
          "cloudfront:CreateInvalidation"
        ],
        "Resource" : [
          "arn:aws:cloudfront::${local.account_id}:distribution/${var.cloudfront_distribution_id}",
          "arn:aws:cloudfront::${local.account_id}:origin-access-control/${var.origin_access_control_id}"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : "sts:GetCallerIdentity",
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "iam:GetRole",
          "iam:ListAttachedRolePolicies",
          "iam:ListAttachedUserPolicies",
          "iam:CreateRole",
          "iam:AttachRolePolicy",
          "iam:GetUser",
          "iam:ListRolePolicies",
          "iam:CreateOpenIDConnectProvider"
        ],
        "Resource" : [
          "arn:aws:iam::${local.account_id}:user/${var.iam_user_name}",
          "arn:aws:iam::${local.account_id}:oidc-provider/${var.github_actions_url}",
          "arn:aws:iam::${local.account_id}:role/${var.iam_role_name}"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "route53:GetChange",
          "route53:GetHostedZone",
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets"
        ],
        "Resource" : [
          "arn:aws:route53:::hostedzone/${var.route53_zone_id}",
          "arn:aws:route53:::change/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : "route53:ListHostedZones",
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "dynamodb:DescribeTable",
          "dynamodb:DescribeContinuousBackups",
          "dynamodb:DescribeTimeToLive"
        ],
        "Resource" : "arn:aws:dynamodb:${var.region}:${local.account_id}:table/${var.table_name}"
      },
      {
        "Effect" : "Allow",
        "Action" : "acm:DescribeCertificate",
        "Resource" : "arn:aws:acm:${var.region}:${local.account_id}:certificate/2bb2124b-bce2-4983-bfb6-0c54f2278ba4"
      },
      {
        "Effect" : "Allow",
        "Action" : "acm:RequestCertificate",
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "kms:DescribeKey",
          "kms:CreateGrant",
          "kms:GenerateDataKey",
          "kms:Decrypt"
        ],
        "Resource" : "arn:aws:kms:${var.region}:${local.account_id}:key/*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "wafv2:GetLoggingConfiguration",
          "wafv2:GetWebACL"
        ],
        "Resource" : "arn:aws:wafv2:${var.region}:${local.account_id}:global/webacl/wafv2-web-acl-cloudfront/c691c21f-4106-47d0-806b-6ea8db7c3593"
      }
    ]
  })
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy
resource "aws_iam_policy" "gha_role_fe_policy" {
  name        = "github-actions-role-fe-policy"
  path        = "/"
  description = "IAM Policy actions for GitHub Actions role"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "cloudfront:CreateInvalidation",
          "cloudfront:GetOriginAccessControl",
          "cloudfront:GetDistribution",
          "cloudfront:ListTagsForResource",
          "cloudfront:UpdateDistribution",
          "cloudfront:ListCachePolicies",
          "cloudfront:ListOriginRequestPolicies",
          "cloudfront:GetCachePolicy",
          "cloudfront:GetOriginRequestPolicy"
        ],
        "Resource" : [
          "arn:aws:cloudfront::${local.account_id}:distribution/${var.cloudfront_distribution_id}",
          "arn:aws:cloudfront::${local.account_id}:origin-access-control/${var.origin_access_control_id}",
          "arn:aws:cloudfront::${local.account_id}:cache-policy/*",
          "arn:aws:cloudfront::${local.account_id}:origin-request-policy/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "cloudformation:GetResource"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "acm:DescribeCertificate",
          "acm:ListTagsForCertificate"
        ],
        "Resource" : "arn:aws:acm:${var.region}:${local.account_id}:certificate/2bb2124b-bce2-4983-bfb6-0c54f2278ba4"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:ListTagsLogGroup",
          "logs:PutRetentionPolicy",
          "logs:CreateLogGroup"
        ],
        "Resource" : "arn:aws:logs:*:${local.account_id}:log-group:*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:PutResourcePolicy",
          "logs:DescribeLogGroups",
          "logs:DescribeResourcePolicies"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "dynamodb:DeleteItem",
          "dynamodb:DescribeTable",
          "dynamodb:DescribeContinuousBackups",
          "dynamodb:DescribeTimeToLive",
          "dynamodb:GetItem",
          "dynamodb:ListTagsOfResource",
          "dynamodb:PutItem"
        ],
        "Resource" : [
          "arn:aws:dynamodb:${var.region}:${local.account_id}:table/${var.table_name}",
          "arn:aws:dynamodb:${var.region}:${local.account_id}:table/${var.counter_table_name}"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "route53:GetChange",
          "route53:GetHostedZone",
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets",
          "route53:ListTagsForResource",
          "route53:GetDNSSEC"
        ],
        "Resource" : [
          "arn:aws:route53:::hostedzone/${var.route53_zone_id}",
          "arn:aws:route53:::change/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : "route53:ListHostedZones",
        "Resource" : "*"
      },

      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetAccelerateConfiguration",
          "s3:GetBucketAcl",
          "s3:GetBucketCORS",
          "s3:GetBucketLocation",
          "s3:GetBucketLogging",
          "s3:GetBucketObjectLockConfiguration",
          "s3:GetBucketPolicy",
          "s3:GetBucketPublicAccessBlock",
          "s3:GetBucketRequestPayment",
          "s3:GetBucketTagging",
          "s3:GetBucketVersioning",
          "s3:GetBucketWebsite",
          "s3:GetEncryptionConfiguration",
          "s3:GetLifecycleConfiguration",
          "s3:GetObject",
          "s3:GetReplicationConfiguration",
          "s3:ListBucket",
          "s3:PutBucketPolicy",
          "s3:PutBucketPublicAccessBlock",
          "s3:PutBucketVersioning",
          "s3:PutObject"
        ],
        "Resource" : [
          "arn:aws:s3:::${var.bucket_name}",
          "arn:aws:s3:::${var.bucket_name}/*",
          "arn:aws:s3:::${var.root_domain}",
          "arn:aws:s3:::${var.root_domain}/*",
          "arn:aws:s3:::${var.s3_website_log_bucket_name}",
          "arn:aws:s3:::${var.s3_website_log_bucket_name}/*",
          "arn:aws:s3:::${var.bucket_logging_fe_name}",
          "arn:aws:s3:::${var.bucket_logging_fe_name}/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "iam:AttachRolePolicy",
          "iam:AttachUserPolicy",
          "iam:CreatePolicy",
          "iam:CreateRole",
          "iam:CreateServiceLinkedRole",
          "iam:DetachUserPolicy",
          "iam:GetOpenIDConnectProvider",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:GetUser",
          "iam:ListAttachedRolePolicies",
          "iam:ListAttachedUserPolicies",
          "iam:ListRolePolicies"
        ],
        "Resource" : [
          "arn:aws:iam::${local.account_id}:user/${var.iam_user_name}",
          "arn:aws:iam::${local.account_id}:oidc-provider/${var.github_actions_url}",
          "arn:aws:iam::${local.account_id}:role/${var.iam_role_name}",
          "arn:aws:iam::${local.account_id}:policy/${var.github_actions_role_fe_policy}",
          "arn:aws:iam::${local.account_id}:policy/${var.terraform_frontend_policy}"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GetKeyPolicy",
          "kms:GetKeyRotationStatus",
          "kms:ListResourceTags",
          "kms:GenerateDataKey"
        ],
        "Resource" : "arn:aws:kms:${var.region}:${local.account_id}:key/*"
      },
      {
        "Effect" : "Allow",
        "Action" : "sts:GetCallerIdentity",
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : "ssm:GetParameter",
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : "apigateway:*",
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "wafv2:GetLoggingConfiguration",
          "wafv2:GetWebACL",
          "wafv2:ListTagsForResource"
        ],
        "Resource" : "arn:aws:wafv2:${var.region}:${local.account_id}:global/webacl/wafv2-web-acl-cloudfront/c691c21f-4106-47d0-806b-6ea8db7c3593"
      }
    ]
  })
}