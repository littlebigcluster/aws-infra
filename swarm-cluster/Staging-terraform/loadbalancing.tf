data "aws_acm_certificate" "cert" {
  domain   = "*.${var.domain_name}"
  statuses = ["ISSUED"]
}



#use the outputs of aws_acm_certificate to create a Route 53 DNS record to confirm domain ownership:
data "aws_route53_zone" "external" {
  name = "${var.domain_name}"
}




# Load Balancing application - needed by many ssl domain name certicate ( up to 25 by LB )
resource "aws_lb" "swarm_lb" {
  name                = "swarm-staging-lb"
  security_groups     = ["${aws_security_group.swarm_lb_sg.id}"]
  subnets             = ["${var.subnet_pub_idz}"]
  idle_timeout        = 400

  tags {
    Name = "swarm-elb-staging"
  }
}

resource "aws_lb_listener" "http_lb_listener" {  
  load_balancer_arn = "${aws_lb.swarm_lb.arn}"  
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
  load_balancer_arn = "${aws_lb.swarm_lb.arn}"  
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        =	"ELBSecurityPolicy-2016-08"
  certificate_arn		=	"${data.aws_acm_certificate.cert.arn}"

  default_action {    
    target_group_arn = "${aws_lb_target_group.swarm_lb.arn}"
    type             = "forward"
  }
}




resource "aws_lb_target_group" "swarm_lb" {
  name     = "swarm-staging-lb"
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
}