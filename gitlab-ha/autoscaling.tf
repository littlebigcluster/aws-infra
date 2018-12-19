## Launch configuration. The AMI created is used by LC
resource "aws_launch_configuration" "gitlab_lc" {
  name_prefix = "gitlab-lc-"
  image_id = "${aws_ami_from_instance.gitlab-ami.id}"
  instance_type = "${var.gitlab_instance_type}"
  security_groups = ["${aws_security_group.sg_gitlab_private.id}"]
  key_name = "${var.key}"
  iam_instance_profile  = "${aws_iam_instance_profile.s3_gitlab_backup.id}"
  lifecycle {
    create_before_destroy = true
  }
}

# Autoscaling Group configuration. Autoscaling uses the LC previously created
# and attach the instances with ELB
resource "aws_autoscaling_group" "gitlab_autoscaling" {
  name = "gitlab-autoscaling-${aws_launch_configuration.gitlab_lc.id}"
  max_size = "${var.gitlab_instances_max}"
  min_size = "${var.gitlab_instances_min}"
  health_check_grace_period = "${var.autoscaling_check_grace}"
  health_check_type = "${var.autoscaling_check_type}"
  desired_capacity = "${var.autoscaling_capacity}"
  force_delete = true
  vpc_zone_identifier = ["${var.subnet_idz}"]
  launch_configuration = "${aws_launch_configuration.gitlab_lc.name}"

  tag {
    key = "Name"
    value = "GITLAB_CE"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}


# data "aws_instances" "gitlab" {
#   instance_tags {
#     Name = "GITLAB_CE"
#   }
# }