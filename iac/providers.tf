# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs 
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.36.0"
    }
  }
  required_version = ">= 1.7.2"
  # Note: must initialize and deploy remote_backend resources prior to 
  #       migrating the state from local backend to the remote backend
  backend "s3" {
    bucket         = "tf-state-bucket-dw-frontend"
    key            = "website/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tf_state_locks_dw_frontend"
  }
}

provider "aws" {
  region = var.region
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter 
data "aws_ssm_parameter" "github_actions_arn" {
  name = "/app/danwadleigh_dev/github_actions_arn"
}

# NOTE: OIDC identity provider created initially via Backend repo
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/arn
data "aws_arn" "github_actions" {
  arn = data.aws_ssm_parameter.github_actions_arn.value
}

# Fetch GitHub's OIDC thumbprint
# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document 
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      identifiers = [data.aws_arn.github_actions.arn]
      type        = "Federated"
    }

    condition {
      test     = "StringEquals"
      variable = "${var.github_actions_url}:sub"
      values = [
        "repo:codecharacter/danwadleigh_dev_frontend:ref:refs/heads/main"
      ]
    }
  }
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role 
# AWS Docs: https://aws.amazon.com/blogs/security/use-iam-roles-to-connect-github-actions-to-actions-in-aws/ 
resource "aws_iam_role" "github_oidc_role" {
  name               = "GitHubActionsRole-frontend"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment 
resource "aws_iam_role_policy_attachment" "github_oidc_role_access" {
  role       = aws_iam_role.github_oidc_role.name
  policy_arn = module.iam.gha_role_fe_policy_arn
}