resource "aws_security_group" "swarm_sg" {
  name        = "swarm-staging-sg"
  description = "A security group for Swarm cluster instances"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port       = 2375
    to_port         = 2375
    protocol        = "tcp"
    security_groups = ["${aws_security_group.swarm_lb_sg.id}"]
    self            = true
  }
  //http
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = ["${aws_security_group.swarm_lb_sg.id}"]
  }
  //https
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = ["${aws_security_group.swarm_lb_sg.id}"]
  }
  //ssh
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  //nfs
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  //egress
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "swarm_lb_sg" {
  name        = "swarm-staging-lb-sg"
  description = "A security group for using swarm load balancer"
  vpc_id      = "${var.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
