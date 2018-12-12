# Bastion ssh/vpn
output "ssh_user" {
  value = "${var.ssh_user}"
}

output "security_group_id" {
  value = "${aws_security_group.bastion.id}"
}

output "asg_id" {
  value = "${aws_autoscaling_group.bastion.id}"
}

output "Bastion IP" {
  value = "${aws_eip.bastion.public_ip}"
}

output "Bastion DNS" {
  value = "${var.bastion_dns_name}"
}
# VPC
output "vpc_id" {
  description = "The ID of the VPC"
  value       = "${module.my-vpc.vpc_id}"
}
# NAT gateways
output "nat_public_ips" {
  description = "List of public Elastic IPs created for AWS NAT Gateway"
  value       = ["${module.my-vpc.nat_public_ips}"]
}
# Subnets
output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = ["${module.my-vpc.private_subnets}"]
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = ["${module.my-vpc.public_subnets}"]
}
