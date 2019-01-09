terraform {
  backend "s3" {
    bucket = "anybox-testing-terraform"
    key    = "aws-base"
    region = "eu-west-1"
  }
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


resource "aws_launch_configuration" "bastion" {
  name_prefix       = "${var.name}-"
  image_id          = "${lookup(var.ami, var.region)}"
  instance_type     = "${var.instance_type}"
  user_data         = "${data.template_file.user_data.rendered}"
  enable_monitoring = "${var.enable_monitoring}"
  associate_public_ip_address = "${aws_eip.bastion.public_ip}"
  iam_instance_profile        = "${var.iam_instance_profile}"
  associate_public_ip_address = "true"
  key_name                    = "${var.key_name}"

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
  name = "${var.name}"

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
