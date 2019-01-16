################################
# DNS
#################################

# Add Route53 entry
data "aws_route53_zone" "my_zone" {
  name = "${var.domainname}"
}


resource "aws_route53_record" "gitlab" {
  zone_id = "${data.aws_route53_zone.my_zone.zone_id}"
  name    = "${local.dns_name}"
  type    = "A"

  alias {
    name                   = "${aws_lb.gitlab_lb.dns_name}"
    zone_id                = "${aws_lb.gitlab_lb.zone_id}"
    evaluate_target_health = true
  }
}



resource "aws_route53_record" "gitlab_ssh" {
  zone_id = "${data.aws_route53_zone.my_zone.zone_id}"
  name    = "${local.dns_name_ssh}"
  type    = "A"

  alias {
    name                   = "${aws_lb.gitlab_nlb.dns_name}"
    zone_id                = "${aws_lb.gitlab_nlb.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "gitlab_registry" {
  zone_id = "${data.aws_route53_zone.my_zone.zone_id}"
  name    = "${local.dns_name_registry}"
  type    = "A"

  alias {
    name                   = "${aws_lb.gitlab_lb.dns_name}"
    zone_id                = "${aws_lb.gitlab_lb.zone_id}"
    evaluate_target_health = true
  }
}
