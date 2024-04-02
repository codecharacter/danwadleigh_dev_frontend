output "route53_zone_id" {
  description = "ID of Route53 Zone"
  value       = data.aws_route53_zone.dns_zone.zone_id
}

output "ssl_cert_arn" {
  description = "ARN of SSL Certificate"
  value       = aws_acm_certificate.ssl_certificate.arn
}
