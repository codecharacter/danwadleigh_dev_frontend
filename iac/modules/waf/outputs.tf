output "aws_wafv2_web_acl_arn" {
  description = "AWS WAFv2 Web ACL ARN"
  value       = aws_wafv2_web_acl.waf_web_acl.arn
}