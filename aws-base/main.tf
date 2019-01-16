locals {
  env = "${terraform.workspace}"
  vpc = {
    "default" = "ANYBOX"
    "testing" = "ANYBOX-TESTING"
  }
  s3-bastion = {
    "default" = "bastion"
    "testing" = "bastion_testing"
  }
  bucket = {
    "default" = "anybox"
    "testing" = "anybox-testing"
  }
  bastion = {
    "default" = "BASTION"
    "testing" = "BASTION-TESTING"
  }
  bucket_name = "${lookup(local.bucket, local.env)}-terraform"
  s3_bucket_name = "${lookup(local.bucket, local.env)}-sshkey-bastion"
  bastion_vpn_name = "${lookup(local.bastion, local.env)}-VPN"
  iam_instance_profile = "s3_${lookup(local.s3-bastion, local.env)}"
  key_name = "${lookup(local.bucket, local.env)}"
  vpc_name = "VPC-${lookup(local.vpc, local.env)}"
  autoscaling_group = "${lookup(local.bastion, local.env)}-VPN"
}

terraform {
  backend "s3" {
    key    = "aws-base"
    region = "eu-west-1"
  }
}

resource "tls_private_key" "anybox-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "${local.key_name}"
  public_key = "${tls_private_key.anybox-key.public_key_openssh}"
}

data "template_file" "user_data" {
  template = "${file("${path.module}/${var.user_data_file}")}"

  vars {
    s3_bucket_name              = "${local.s3_bucket_name}"
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


resource "aws_launch_configuration" "bastion" {
  name_prefix       = "${local.bastion_vpn_name}"
  image_id          = "${lookup(var.ami, var.region)}"
  instance_type     = "${var.instance_type}"
  user_data         = "${data.template_file.user_data.rendered}"
  enable_monitoring = "${var.enable_monitoring}"
  associate_public_ip_address = "${aws_eip.bastion.public_ip}"
  iam_instance_profile        = "${local.iam_instance_profile}"
  associate_public_ip_address = "true"
  key_name                    = "${local.key_name}"

  security_groups = [
    "${compact(concat(list(aws_security_group.bastion.id), split(",", "${var.security_group_ids}")))}",
  ]
  root_block_device {
    volume_size = "${var.instance_volume_size_gb}"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "bastion" {
  name = "${local.autoscaling_group}"

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
          map("key", "Name", "value", "${local.bastion_vpn_name}", "propagate_at_launch", true),
          map("key", "EIP", "value", "${var.eip}", "propagate_at_launch", true)
        ),
        var.extra_tags)
      }",
  ]

  lifecycle {
    create_before_destroy = true
  }
}
