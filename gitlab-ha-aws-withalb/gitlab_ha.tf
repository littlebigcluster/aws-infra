#######
#
# Create AWS Resources and deploy gitlab in HA
#
######

# Use AWS as provider

provider "aws" {
  # access_key = "${var.access_key}"
  # secret_key = "${var.secret_key}"
  region = "${var.aws_region}"
}

# Declare data source AZ
data "aws_availability_zones" "available" {}


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
    cidr_blocks = ["${var.vpc_cidr}"]
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

# EFS: Will provide a NFS(file sharing) service to store common files and repo
resource "aws_efs_file_system" "gitlab_efs" {
  creation_token = "gitlab_efs_001"

  tags {
    Name = "gitlab_efs"
    User = "anybox"
  }
  # lifecycle {
  #   prevent_destroy = true
  # }
}

resource "aws_efs_mount_target" "gitlab_efs_mt" {
  count = "${var.efs_mt_count}"
  file_system_id = "${aws_efs_file_system.gitlab_efs.id}"
  subnet_id      = "${element(var.subnet_idz,count.index)}"
  # subnet_id      = "${element(aws_subnet.net-gitlab-private.*.id,count.index)}"
  security_groups = ["${aws_security_group.sg_gitlab_public.id}", "${aws_security_group.sg_gitlab_private.id}"]
}


# RDS - PostgreSQL: Main DB used by GitLab
resource "aws_db_instance" "gitlab-postgres" {
  allocated_storage	= 10
  engine		= "postgres"
  engine_version	= "9.6.10"
  instance_class	= "${var.postgres_instance}"
  name			= "${var.postgres_gitlab_dbname}"
  username		= "${var.postgres_gitlab_user}"
  password		= "${var.postgres_gitlab_pass}"
  db_subnet_group_name  = "${aws_db_subnet_group.db_net_group.name}"
  vpc_security_group_ids = ["${aws_security_group.sg_gitlab_postgresql.id}"]
  skip_final_snapshot = true
  tags {
    Name = "gitlab-postgres"
    User = "anybox"
  }
}

# Elasticache redis: Redis is used by Gitlab to store Jobs
resource "aws_elasticache_cluster" "gitlab-redis" {
  cluster_id           = "gitlab-redis-001"
  engine               = "redis"
  engine_version       = "3.2.10"
  node_type            = "${var.elasticache_type}"
  port                 = 6379
  num_cache_nodes      = 1
  parameter_group_name = "${var.elasticache_parameter_group}"
  subnet_group_name    = "${aws_elasticache_subnet_group.redis_net_group.name}"
  security_group_ids   = ["${aws_security_group.sg_gitlab_redis.id}"]
  tags {
    Name = "gitlab-redis"
    User = "anybox"
  }
}



# resources to AWS S3 gitlab backup
# This is just a sample definition of IAM instance profile which is allowed to backup to S3.

resource "aws_iam_instance_profile" "s3_gitlab_backup" {
  name = "s3_gitlab_backup"
  role = "${aws_iam_role.s3_gitlab_backup.name}"
}

resource "aws_iam_role" "s3_gitlab_backup" {
  name = "s3_gitlab_backup"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "s3_gitlab_backup_policy" {
  name = "s3_gitlab_backup-policy"
  role = "${aws_iam_role.s3_gitlab_backup.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": ["s3:ListBucket"],
            "Resource": ["arn:aws:s3:::${var.s3_backup_bucket}"]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject"
            ],
            "Resource": ["arn:aws:s3:::${var.s3_backup_bucket}/*"]
        }
    ]
}
EOF
}

resource "aws_s3_bucket" "s3-gitlab-backup" {
  bucket = "${var.s3_backup_bucket}"
  acl    = "private"

  tags {
    Name        = "${var.s3_backup_bucket}"
    Environment = "Backup"
  }
  # We explicitly prevent destruction using terraform. Remove this only if you really know what you're doing.
  lifecycle {
    # prevent_destroy = true
  }
}


## Gitlab SEED  -  Config gitlab CE with Ansible
resource "aws_instance" "gitlab-seed" {
  instance_type = "${var.seed_instance_type}"
  ami = "${var.seed_ami}"
  key_name = "${var.key}"
  # key_name = "${aws_key_pair.gitlab-keypair.id}"
  vpc_security_group_ids = ["${aws_security_group.sg_gitlab_public.id}"]
  subnet_id = "${var.subnet_pub_idz[0]}"
  iam_instance_profile = "s3_gitlab_backup"
  # subnet_id = "${aws_subnet.net-gitlab-public.0.id}"
  tags {
    Name = "gitlab-seed"
    User = "anybox"
  }

  provisioner "local-exec" {
    command = <<SCRIPT
INSTANCE_IP=${aws_instance.gitlab-seed.public_ip} \
RDS_ENDPOINT=${aws_db_instance.gitlab-postgres.endpoint} \
RDS_PASS=${var.postgres_gitlab_pass} \
REDIS_ENDPOINT=${aws_elasticache_cluster.gitlab-redis.cache_nodes.0.address} \
KEYPAIR=${var.key_path} \
FQN_DOMAIN=${var.dnsname} \
EFS="${aws_efs_file_system.gitlab_efs.id}.efs.${var.aws_region}.amazonaws.com" \
./configure_instances.sh
SCRIPT
  }
}



# Genarate ACM certificate to git.mondomain.com and attach it to LB !
resource "aws_acm_certificate" "gitlab_cert" {
  domain_name       = "*.${var.domainname}"
  validation_method = "DNS"

  tags {
    Environment = "gitlab"
  }

  lifecycle {
    create_before_destroy = true
  }
}

#use the outputs of aws_acm_certificate to create a Route 53 DNS record to confirm domain ownership:
data "aws_route53_zone" "external" {
  name = "${var.domainname}"
}

resource "aws_route53_record" "validation" {
  name    = "${aws_acm_certificate.gitlab_cert.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.gitlab_cert.domain_validation_options.0.resource_record_type}"
  zone_id = "${data.aws_route53_zone.external.zone_id}"
  records = ["${aws_acm_certificate.gitlab_cert.domain_validation_options.0.resource_record_value}"]
  ttl     = "60"
}

#resource to wait for the newly created certificate to become valid
resource "aws_acm_certificate_validation" "gitlab_cert" {
  certificate_arn = "${aws_acm_certificate.gitlab_cert.arn}"
  validation_record_fqdns = [
    "${aws_route53_record.validation.fqdn}",
  ]
}




# Load Balancing application - needed by many ssl domain name certicate ( up to 25 by LB )
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


# Forward action

# resource "aws_lb_listener_rule" "gitlab_routing" {
#   listener_arn = "${aws_lb_listener.https_lb_listener.arn}"
#   priority     = 99

#   action {
#     type             = "forward"
#     target_group_arn = "${aws_lb_target_group.gitlab_lb.arn}"
#   }

#   condition {
#     field  = "host-header"
#     values = ["git.anybox.cloud"]
#   }
# }





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
}




# Create a new ALB Target Group attachment
resource "aws_autoscaling_attachment" "gitlab_asglb" {
  autoscaling_group_name = "${aws_autoscaling_group.gitlab_autoscaling.id}"
  alb_target_group_arn   = "${aws_lb_target_group.gitlab_lb.arn}"
}






# Load Balancing network - needed to gitlab ssh access
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

# Create a new ALB Target Group attachment
resource "aws_autoscaling_attachment" "gitlab_asgssh" {
  autoscaling_group_name = "${aws_autoscaling_group.gitlab_autoscaling.id}"
  alb_target_group_arn   = "${aws_lb_target_group.gitlab_ssh.arn}"
}








# Add Route53 entry
data "aws_route53_zone" "my_zone" {
  name = "${var.domainname}"
}


resource "aws_route53_record" "gitlab" {
  zone_id = "${data.aws_route53_zone.my_zone.zone_id}"
  name    = "${var.dnsname}"
  type    = "A"

  alias {
    name                   = "${aws_lb.gitlab_lb.dns_name}"
    zone_id                = "${aws_lb.gitlab_lb.zone_id}"
    evaluate_target_health = true
  }
}


# Create AMI for autoscaling. This image is created based on
# the seed previously configured
# resource "random_id" "server" {
#   # keepers = {
#   #   # Generate a new id each time we switch to a new AMI id
#   #   ami_id = "${var.ami_id}"
#   # }
#   byte_length = 8
# }

resource "aws_ami_from_instance" "gitlab-ami" {
    name = "${var.ami_id}-${replace(timestamp(), ":", "")}"
    source_instance_id = "${aws_instance.gitlab-seed.id}"
    lifecycle {
      ignore_changes = true
    }
  #   lifecycle {
  #     create_before_destroy = true
  # }
}

# Launch configuration. The AMI created is used by LC
resource "aws_launch_configuration" "gitlab_lc" {
  name_prefix = "gitlab-lc-"
  image_id = "${aws_ami_from_instance.gitlab-ami.id}"
  instance_type = "${var.gitlab_instance_type}"
  security_groups = ["${aws_security_group.sg_gitlab_private.id}"]
  key_name = "${var.key}"
  iam_instance_profile  = "${aws_iam_instance_profile.s3_gitlab_backup.id}"
  # key_name = "${aws_key_pair.gitlab-keypair.id}"
  lifecycle {
    create_before_destroy = true
  }
}

# Autoscaling Group configuration. Autoscaling uses the LC previously created
# and attach the instances with ELB
resource "aws_autoscaling_group" "gitlab_autoscaling" {
  # availability_zones = ["${data.aws_availability_zones.available.names[0]}", "${data.aws_availability_zones.available.names[1]}"]
  name = "gitlab-autoscaling-${aws_launch_configuration.gitlab_lc.id}"
  max_size = "${var.gitlab_instances_max}"
  min_size = "${var.gitlab_instances_min}"
  health_check_grace_period = "${var.autoscaling_check_grace}"
  health_check_type = "${var.autoscaling_check_type}"
  desired_capacity = "${var.autoscaling_capacity}"
  force_delete = true
  # load_balancers = ["${aws_lb.gitlab_lb.id}","${aws_lb.gitlab_nlb.id}"]
  vpc_zone_identifier = ["${var.subnet_idz}"]
  # vpc_zone_identifier = ["${aws_subnet.net-gitlab-private.*.id}"]
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
