output "gitlab-lb" {
  value = "${aws_lb.gitlab_lb.dns_name}"
}

output "DNS Gitlab" {
  value = "${var.dnsname}"
}