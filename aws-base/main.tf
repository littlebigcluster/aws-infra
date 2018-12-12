resource "aws_security_group" "bastion" {
  name        = "${var.name}"
  vpc_id      = "${module.my-vpc.vpc_id}"
  description = "Bastion security group (only SSH and VPN inbound access is allowed)"

  tags {
    Name = "${var.name}"
  }
}

resource "aws_security_group_rule" "ssh_ingress" {
  type              = "ingress"
  from_port         = "22"
  to_port           = "22"
  protocol          = "tcp"
  cidr_blocks       = "${var.allowed_cidr}"
  ipv6_cidr_blocks  = "${var.allowed_ipv6_cidr}"
  security_group_id = "${aws_security_group.bastion.id}"
}

resource "aws_security_group_rule" "vpn_ingress" {
  type              = "ingress"
  from_port         = "1194"
  to_port           = "1194"
  protocol          = "udp"
  cidr_blocks       = "${var.allowed_cidr}"
  ipv6_cidr_blocks  = "${var.allowed_ipv6_cidr}"
  security_group_id = "${aws_security_group.bastion.id}"
}
resource "aws_security_group_rule" "ssh_sg_ingress" {
  count                    = "${length(var.allowed_security_groups)}"
  type                     = "ingress"
  from_port                = "22"
  to_port                  = "22"
  protocol                 = "tcp"
  source_security_group_id = "${element(var.allowed_security_groups, count.index)}"
  security_group_id        = "${aws_security_group.bastion.id}"
}

resource "aws_security_group_rule" "vpn_sg_ingress" {
  count                    = "${length(var.allowed_security_groups)}"
  type                     = "ingress"
  from_port                = "1194"
  to_port                  = "1194"
  protocol                 = "udp"
  source_security_group_id = "${element(var.allowed_security_groups, count.index)}"
  security_group_id        = "${aws_security_group.bastion.id}"
}
resource "aws_security_group_rule" "bastion_all_egress" {
  type      = "egress"
  from_port = "0"
  to_port   = "65535"
  protocol  = "all"

  cidr_blocks = [
    "0.0.0.0/0",
  ]

  ipv6_cidr_blocks = [
    "::/0",
  ]

  security_group_id = "${aws_security_group.bastion.id}"
}



data "template_file" "user_data" {
  template = "${file("${path.module}/${var.user_data_file}")}"

  vars {
    s3_bucket_name              = "${var.s3_bucket_name}"
    ssh_user                    = "${var.ssh_user}"
    keys_update_frequency       = "${var.keys_update_frequency}"
    enable_hourly_cron_updates  = "${var.enable_hourly_cron_updates}"
    # additional_user_data_script = "${var.additional_user_data_script}"
    additional_user_data_script = <<EOF
REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep region | awk -F\" '{print $4}')
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
aws ec2 associate-address --region $REGION --instance-id $INSTANCE_ID --allocation-id ${aws_eip.bastion.id}
EOF
  }
}


resource "aws_eip" "bastion" {
  vpc = true
}

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




//resource "aws_instance" "bastion" {
//  ami                    = "${var.ami}"
//  instance_type          = "${var.instance_type}"
//  iam_instance_profile   = "${var.iam_instance_profile}"
//  subnet_id              = "${var.subnet_id}"
//  vpc_security_group_ids = ["${aws_security_group.bastion.id}"]
//  user_data              = "${template_file.user_data.rendered}"
//
//  count                  = 1
//
//  tags {
//    Name = "${var.name}"
//  }
//}

resource "aws_launch_configuration" "bastion" {
  name_prefix       = "${var.name}-"
  image_id          = "${var.ami}"
  instance_type     = "${var.instance_type}"
  user_data         = "${data.template_file.user_data.rendered}"
  enable_monitoring = "${var.enable_monitoring}"
  associate_public_ip_address = "${aws_eip.bastion.public_ip}"

  security_groups = [
    "${compact(concat(list(aws_security_group.bastion.id), split(",", "${var.security_group_ids}")))}",
  ]

  root_block_device {
    volume_size = "${var.instance_volume_size_gb}"
  }

  iam_instance_profile        = "${var.iam_instance_profile}"
  # associate_public_ip_address = "${var.associate_public_ip_address}"
  associate_public_ip_address = "true"
  key_name                    = "${var.key_name}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "bastion" {
  name = "${var.apply_changes_immediately ? aws_launch_configuration.bastion.name : var.name}"

  vpc_zone_identifier = [
    "${module.my-vpc.public_subnets}",
  ]

  desired_capacity          = "1"
  min_size                  = "1"
  max_size                  = "1"
  health_check_grace_period = "60"
  health_check_type         = "EC2"
  force_delete              = false
  wait_for_capacity_timeout = 0
  launch_configuration      = "${aws_launch_configuration.bastion.name}"

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances",
  ]

  tags = [
    "${concat(
        list(
          map("key", "Name", "value", "${var.name}", "propagate_at_launch", true),
          map("key", "EIP", "value", "${var.eip}", "propagate_at_launch", true)
        ),
        var.extra_tags)
      }",
  ]

  lifecycle {
    create_before_destroy = true
  }
}
