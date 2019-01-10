# Create a RDS subnet group
resource "aws_db_subnet_group" "db_net_group" {
  name = "db-net-group"
  subnet_ids = ["${var.subnet_idz}"]
  # subnet_ids = ["${aws_subnet.net-gitlab-private.*.id}"]

  tags {
    Name = "gitlab_db_net_group"
    User = "anybox"
  }
}

# Create Elasticache Subnet group
resource "aws_elasticache_subnet_group" "redis_net_group" {
  name = "redis-net-group"
  subnet_ids = ["${var.subnet_idz}"]
  # subnet_ids = ["${aws_subnet.net-gitlab-private.*.id}"]

}

# Security groups
resource "aws_security_group" "sg_gitlab_public" {
  name = "sg_gitlab_public"
  description = "SSH, HTTP and HTTPS Access for ELB and Seed"
  vpc_id   = "${var.vpc_id}"
  # vpc_id = "${aws_vpc.vpc-gitlab.id}"
  # Secure shell
  ingress {
    from_port 	= 22
    to_port 	= 22
    protocol 	= "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # HTTP
  ingress {
    from_port 	= 80
    to_port 	= 80
    protocol 	= "tcp"
    cidr_blocks	= ["0.0.0.0/0"]
  }
  # HTTPS
  ingress {
    from_port 	= 443
    to_port 	= 443
    protocol 	= "tcp"
    cidr_blocks	= ["0.0.0.0/0"]
  }
  #Internet Access
  egress {
    from_port	= 0
    to_port 	= 0
    protocol	= "-1"
    cidr_blocks	= ["0.0.0.0/0"]
  }

  tags {
    Name = "gitlab-sg-public"
    User = "anybox"
  }
}

resource "aws_security_group" "sg_gitlab_private" {
  name        = "sg_gitlab_private"
  description = "Internal Instances"
  vpc_id   = "${var.vpc_id}"
  # vpc_id      = "${aws_vpc.vpc-gitlab.id}"
  # SSH: Internal only
  ingress {
    from_port 	= 0
    to_port 	= 0
    protocol 	= "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  #Internet Access
  egress {
    from_port	= 0
    to_port 	= 0
    protocol	= "-1"
    cidr_blocks	= ["0.0.0.0/0"]
  }

  tags {
    Name = "gitlab-sg-private"
    User = "anybox"
  }
}

resource "aws_security_group" "sg_gitlab_postgresql" {
  name= "sg_gitlab_postgresql"
  description = "PostgreSQL Security Group"
  vpc_id   = "${var.vpc_id}"
  # vpc_id      = "${aws_vpc.vpc-gitlab.id}"
  # PostgreSQL access to internal instances and seed
  ingress {
    from_port        = 5432
    to_port          = 5432
    protocol         = "tcp"
    security_groups  = ["${aws_security_group.sg_gitlab_public.id}", "${aws_security_group.sg_gitlab_private.id}"]
  }

  tags {
    Name = "gitlab-sg-postgresql"
    User = "anybox"
  }
}

resource "aws_security_group" "sg_gitlab_redis" {
  name= "sg_gitlab_redis"
  description = "Redis Security Group"
  vpc_id   = "${var.vpc_id}"
  # vpc_id      = "${aws_vpc.vpc-gitlab.id}"
  # PostgreSQL access to internal instances and seed
  ingress {
    from_port        = 6379
    to_port          = 6379
    protocol         = "tcp"
    security_groups  = ["${aws_security_group.sg_gitlab_public.id}", "${aws_security_group.sg_gitlab_private.id}"]
  }

  tags {
    Name = "gitlab-sg-redis"
    User = "anybox"
  }
}