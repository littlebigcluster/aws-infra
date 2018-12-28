################################
# DNS
#################################

# Add Route53 entry
data "aws_route53_zone" "my_zone" {
  name = "${var.domain_name}"
}


resource "aws_route53_record" "swarm" {
  zone_id = "${data.aws_route53_zone.my_zone.zone_id}"
  name    = "${var.cluster}-${var.environment}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = "${aws_lb.swarm_lb.dns_name}"
    zone_id                = "${aws_lb.swarm_lb.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "traefik" {
  zone_id = "${data.aws_route53_zone.my_zone.zone_id}"
  name    = "traefik-${var.environment}"
  type    = "CNAME"
  records = ["${var.cluster}-${var.environment}.${var.domain_name}"]
  ttl     = "300"
}

resource "aws_route53_record" "portainer" {
  zone_id = "${data.aws_route53_zone.my_zone.zone_id}"
  name    = "portainer-${var.environment}"
  type    = "CNAME"
  records = ["${var.cluster}-${var.environment}.${var.domain_name}"]
  ttl     = "300"
}