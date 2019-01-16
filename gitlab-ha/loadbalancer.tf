### Load Balancing application - needed by many ssl domain name certicate ( up to 25 by LB )
resource "aws_lb" "gitlab_lb" {
  name                = "applications-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups     = ["${aws_security_group.sg_gitlab_public.id}"]
  subnets = ["${var.subnet_pub_idz}"]
  idle_timeout        = 120

  tags {
    Name = "ALB-Gitlab"
  }
}
resource "aws_lb_listener" "http_lb_listener" {  
  load_balancer_arn = "${aws_lb.gitlab_lb.arn}"  
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
resource "aws_lb_listener" "https_lb_listener" {  
  load_balancer_arn = "${aws_lb.gitlab_lb.arn}"  
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        =	"ELBSecurityPolicy-2016-08"
  certificate_arn = "${aws_acm_certificate.gitlab_cert.arn}"

  default_action {    
    target_group_arn = "${aws_lb_target_group.gitlab_lb.arn}"
    type             = "forward"
  }
}


# Forward action to target group gitlab
resource "aws_lb_listener_rule" "gitlab_routing" {
  listener_arn = "${aws_lb_listener.https_lb_listener.arn}"
  priority     = 99

  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.gitlab_lb.arn}"
  }
  condition {
    field  = "host-header"
    values = ["${local.dns_name}"]
  }
}

resource "aws_lb_target_group" "gitlab_lb" {
  name     = "gitlabgrp"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"
  health_check {    
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 4
    interval            = 5
    matcher             = "200-499"
    port                = "80"
  }
  stickiness {
    type = "lb_cookie"
    cookie_duration = 1800
    enabled = true
  }
}

# Create a new ALB Target Group attachment
resource "aws_autoscaling_attachment" "gitlab_asglb" {
  autoscaling_group_name = "${aws_autoscaling_group.gitlab_autoscaling.id}"
  alb_target_group_arn   = "${aws_lb_target_group.gitlab_lb.arn}"
  lifecycle {
    create_before_destroy = true
  }
}




### Load Balancing network - tcp - needed to gitlab ssh access
resource "aws_lb" "gitlab_nlb" {
  name                = "network-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets = ["${var.subnet_pub_idz}"]

  tags {
    Name = "NLB-Gitlab"
  }
}

resource "aws_lb_listener" "ssh_lb_listener" {  
  load_balancer_arn = "${aws_lb.gitlab_nlb.arn}"  
  port              = "22"
  protocol          = "TCP"

  # Be sure to create an aws_lb_target_group first
  default_action {
    target_group_arn = "${aws_lb_target_group.gitlab_ssh.arn}"
    type             = "forward"
  }
}
resource "aws_lb_target_group" "gitlab_ssh" {
  name     = "gitlabssh"
  protocol = "TCP"
  port     = 22
  vpc_id      = "${var.vpc_id}"
}

# Create a new NLB Target Group attachment
resource "aws_autoscaling_attachment" "gitlab_asgssh" {
  autoscaling_group_name = "${aws_autoscaling_group.gitlab_autoscaling.id}"
  alb_target_group_arn   = "${aws_lb_target_group.gitlab_ssh.arn}"
  lifecycle {
    create_before_destroy = true
  }
}
