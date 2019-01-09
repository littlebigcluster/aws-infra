data "aws_route53_zone" "external" {
  name = "${var.domain_name}"
}

resource "aws_route53_record" "bastion" {
  zone_id = "${data.aws_route53_zone.external.zone_id}"
  name    = "${var.bastion_dns_name}"
  type    = "A"
  ttl     = "600"
  records = ["${aws_eip.bastion.public_ip}"]
}