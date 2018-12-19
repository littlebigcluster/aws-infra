# Generate ACM certificate to git.mondomain.com and attach it to LB !
resource "aws_acm_certificate" "gitlab_cert" {
  domain_name       = "*.${var.domainname}"
  validation_method = "DNS"

  tags {
    Environment = "gitlab"
  }

  lifecycle {
    create_before_destroy = true
  }
}

#use the outputs of aws_acm_certificate to create a Route 53 DNS record to confirm domain ownership:
data "aws_route53_zone" "external" {
  name = "${var.domainname}"
}

resource "aws_route53_record" "validation" {
  name    = "${aws_acm_certificate.gitlab_cert.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.gitlab_cert.domain_validation_options.0.resource_record_type}"
  zone_id = "${data.aws_route53_zone.external.zone_id}"
  records = ["${aws_acm_certificate.gitlab_cert.domain_validation_options.0.resource_record_value}"]
  ttl     = "60"
}

#resource to wait for the newly created certificate to become valid
resource "aws_acm_certificate_validation" "gitlab_cert" {
  certificate_arn = "${aws_acm_certificate.gitlab_cert.arn}"
  validation_record_fqdns = [
    "${aws_route53_record.validation.fqdn}",
  ]
}