variable "aws_region" {
  default = "eu-west-1"
}
variable "vpc_cidr" {
  default = "10.55.0.0/16"
}
variable "vpc_id" {
  description = "The ID of the VPC in which to deploy the Gitlab"
  default = "vpc-013acfdb59ec46838"
}
variable "subnet_idz" {
  type = "list"
  default = ["subnet-0688b176ea5fee282","subnet-038a9d698f3d32fa9","subnet-02209ff3fe7e8e392"]
}
variable "subnet_pub_idz" {
  type = "list"
  default = ["subnet-018a07c6522541117","subnet-0f04422bfa3f290eb","subnet-08f555826e2c1cec5"]
}
variable "key_path" {
  default = "~/.ec2/anybox-testing.pem"
}
variable "key" {
  default = "anybox-testing"
}
variable "dnsname" {
  default = "gitlab-testing.anybox.cloud"
}
variable "dnsnamessh" {
  default = "git-testing.anybox.cloud"
}
variable "domainname" {
  default = "anybox.cloud"
}
variable "s3_backup_bucket" {
  default = "anybox-testing-gitlab-backup"
}

variable "efs_mt_count" {}
variable "postgres_instance" {}
variable "postgres_gitlab_dbname" {}
variable "postgres_gitlab_user" {}
variable "postgres_gitlab_pass" {
  default = "psqlpassword"
}
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
variable "ldap_password" {
  default = "ldappassword"
}
variable "smtp_password" {
  default = "smtppassword"
}
variable "gitlab_root_password" {
  default = "gitlab_root_password"
}
