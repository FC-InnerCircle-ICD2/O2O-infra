data "aws_acm_certificate" "acm" {
  domain      = "gaebalmin.com"
  statuses    = ["ISSUED"]
  most_recent = true
}