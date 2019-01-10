#######
#
# Create AWS Resources and deploy gitlab in HA
#
######
terraform {
  backend "s3" {
    bucket = "anybox-testing-terraform"
    key    = "gitlab-ha"
    region = "eu-west-1"
  }
}

# Use AWS as provider

provider "aws" {
  # access_key = "${var.access_key}"
  # secret_key = "${var.secret_key}"
  region = "${var.aws_region}"
}

# Declare data source AZ
data "aws_availability_zones" "available" {}


## Gitlab SEED  -  Config gitlab CE with Ansible
resource "aws_instance" "gitlab-seed" {
  instance_type = "${var.seed_instance_type}"
  ami = "${var.seed_ami}"
  key_name = "${var.key_name}"
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
LDAP_PASS=${var.ldap_password} \
SMTP_PASS=${var.smtp_password} \
REDIS_ENDPOINT=${aws_elasticache_cluster.gitlab-redis.cache_nodes.0.address} \
KEYPAIR=${var.key_path} \
FQN_DOMAIN=${var.dnsname} \
FQN_DOMAIN_SSH=${var.dnsnamessh} \
FQN_DOMAIN_REGISTRY=${var.dnsnameregistry} \
GITLABROOT_PASS=${var.gitlab_root_password} \
S3_BUCKET=${var.s3_backup_bucket} \
RUNNER_TOKEN=${var.runner_token} \
EFS="${aws_efs_file_system.gitlab_efs.id}.efs.${var.aws_region}.amazonaws.com" \
./configure_instances.sh
SCRIPT
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
      create_before_destroy = true
  }
}
