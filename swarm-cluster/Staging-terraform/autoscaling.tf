resource "aws_launch_configuration" "swarm_manager_as_conf" {
  name_prefix     = "swarm-manager-as-conf-"
  image_id        = "${var.ec2_ami-manager}"
  instance_type   = "${var.manager_size}"
  key_name        = "${var.key}"
  security_groups = ["${aws_security_group.swarm_sg.id}"]
  iam_instance_profile  = "${aws_iam_instance_profile.swarm_cluster_profile.id}"

  user_data       = <<EOF
#!/bin/bash
export ROLE=manager
sleep 15
export INSTANCE=$(curl http://169.254.169.254/latest/meta-data/instance-id)
export AWS_DEFAULT_REGION=${var.aws_region}
python3 /home/admin/init.py > /home/admin/init.log
EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "swarm_manager_asg" {
  name                  = "swarm-manager-staging-asg"
  max_size              = 5
  min_size              = 1
  desired_capacity      = "${var.manager_count}"
  availability_zones    = "${var.aws_az}"
  vpc_zone_identifier   = "${var.subnet_idz}"
  launch_configuration  = "${aws_launch_configuration.swarm_manager_as_conf.name}"

  tag {
    key                 = "Name"
    value               = "SwarmManager-staging"
    propagate_at_launch = true
  }

  tag {
    key                 = "Init"
    value               = "false"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Create a new ALB Target Group attachment
resource "aws_autoscaling_attachment" "swarm_manager_asg" {
  autoscaling_group_name = "${aws_autoscaling_group.swarm_manager_asg.id}"
  alb_target_group_arn   = "${aws_lb_target_group.swarm_lb.arn}"
}




resource "aws_launch_configuration" "swarm_worker_as_conf" {
  name_prefix     = "swarm-worker-as-conf-"
  image_id        = "${var.ec2_ami-worker}"
  instance_type   = "${var.worker_size}"
  # spot_price      = "${var.spot_worker_price}"
  key_name        = "${var.key}"
  security_groups = ["${aws_security_group.swarm_sg.id}"]
  iam_instance_profile  = "${aws_iam_instance_profile.swarm_cluster_profile.id}"

  user_data       = <<EOF
#!/bin/bash
export ROLE=worker
sleep 15
export INSTANCE=$(curl http://169.254.169.254/latest/meta-data/instance-id)
export AWS_DEFAULT_REGION=${var.aws_region}
python3 /home/admin/init.py > /home/admin/init.log
EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "swarm_worker_asg" {
  name                  = "swarm-worker-staging-asg"
  max_size              = 1000
  min_size              = 1
  desired_capacity      = "${var.worker_count}"
  availability_zones    = "${var.aws_az}"
  vpc_zone_identifier   = "${var.subnet_idz}"
  launch_configuration  = "${aws_launch_configuration.swarm_worker_as_conf.name}"
  depends_on            = ["aws_autoscaling_group.swarm_manager_asg"]

  tag {
    key                 = "Name"
    value               = "SwarmWorker-staging"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Create a new ALB Target Group attachment
resource "aws_autoscaling_attachment" "swarm_worker_asg" {
  autoscaling_group_name = "${aws_autoscaling_group.swarm_worker_asg.id}"
  alb_target_group_arn   = "${aws_lb_target_group.swarm_lb.arn}"
}
