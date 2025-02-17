data "aws_route53_zone" "zone" {
  name         = "gaebalmin.com"
  private_zone = false
}

resource "aws_route53_record" "rootdomain" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "gaebalmin.com"
  type    = "A"

  alias {
    name                   = var.alb.dns_name
    zone_id                = var.alb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "subdomain" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "ceo.gaebalmin.com"
  type    = "A"

  alias {
    name                   = var.alb.dns_name
    zone_id                = var.alb.zone_id
    evaluate_target_health = true
  }
}