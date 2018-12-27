variable "aws_region" {
  default = "eu-west-1"
}
variable "vpc_cidr" {
  default = "10.55.0.0/16"
}
variable "vpc_id" {
  description = "The ID of the VPC in which to deploy the Gitlab"
  default = "vpc-0acf96d67d37208f0"
}
variable "subnet_idz" {
  type = "list"
  default = ["subnet-05006ed2f72e5ef71","subnet-00350e21671fa05e1","subnet-074673bb2a39ff209"]
}
variable "subnet_pub_idz" {
  type = "list"
  default = ["subnet-0ec328f140cdf6cdd","subnet-09d62f84d8dee5613","subnet-0fda32ba010f10ad4"]
}
variable "dnsname" {
  default = "gitlab.anybox.cloud"
}
variable "dnsnamessh" {
  default = "git.anybox.cloud"
}
variable "domainname" {
  default = "anybox.cloud"
}
variable "dnsnameregistry" {
  default = "registry.anybox.cloud"
}
variable "s3_backup_bucket" {
  default = "anybox-gitlab-backup"
}

variable "efs_mt_count" {}
variable "postgres_instance" {}
variable "postgres_gitlab_dbname" {}
variable "postgres_gitlab_user" {}
variable "postgres_gitlab_pass" {}
variable "elasticache_type" {}
variable "elasticache_parameter_group" {}
variable "seed_instance_type" {}
variable "seed_ami" {}
variable "gitlab_instance_type" {}
variable "ami_id" {}
variable "gitlab_instances_max" {}
variable "gitlab_instances_min" {}
variable "autoscaling_check_grace" {}
variable "autoscaling_check_type" {}
variable "autoscaling_capacity" {}
variable "ldap_password" {}
variable "smtp_password" {}
variable "gitlab_root_password" {}
variable "key_path" {
  default = "~/.ec2/anybox.pem"
}


#### Runner

variable "runner_name" {
  default = "gitlab_runner"
}
variable "gitlab_url" {
  default = "https://gitlab.anybox.cloud/"
}
variable "runner_token" {
  default = "xxxxxxxxxxxxxxxxxx"
}
variable "runner_token_trinita" {
  default = "xxxxxxxxxxxxxxxxxx"
}
variable "environment" {
  default = "gitlab-ci"
}
variable "gitlab_runner_version" {}
variable "docker_machine_version" {}
variable "docker_machine_instance_type" {}
variable "cache_bucket_prefix" {}
variable "key_name" {}