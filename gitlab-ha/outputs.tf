output "gitlab-lb" {
  value = "${aws_lb.gitlab_lb.dns_name}"
}

output "DNS Gitlab" {
  value = "${var.dnsname}"
}

output "DNS Git access" {
  value = "${var.dnsnamessh}"
}

output "RDS Adress" {
  value = "${aws_db_instance.gitlab-postgres.address}"
}