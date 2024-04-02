output "gha_role_fe_policy_arn" {
  description = "GitHub Actions role IAM policy arn"
  value       = aws_iam_policy.gha_role_fe_policy.arn
}

output "tf_fe_policy_arn" {
  description = "terraform_frontend user IAM policy arn"
  value       = aws_iam_policy.tf_fe_policy.arn
}
