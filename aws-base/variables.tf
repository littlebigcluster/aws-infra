variable "region" {
  default = "eu-west-1"
}
variable "vpc_name" {
  default = "VPC-ANYBOX"
}
variable "vpc_cidr" {
  description = "The VPC cidr"
  default = "10.55.0.0/16"
}
variable "aws_az" {
  type    = "list"
  default = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}
variable "subnet_priv" {
  type = "list"
  default = ["10.55.10.0/24", "10.55.20.0/24", "10.55.30.0/24"]
}
variable "subnet_pub" {
  type = "list"
  default = ["10.55.1.0/24", "10.55.2.0/24", "10.55.3.0/24"]
}
variable "bastion_size" {
  default = "t3.micro"
}
variable "bastion_dns_name" {
  default = "bastion.anybox.cloud"
}
variable "domain_name" {
  default = "anybox.cloud"
}

variable "allowed_cidr" {
  type = "list"
  default = ["0.0.0.0/0"]
  description = "A list of CIDR Networks to allow ssh access to."
}

variable "allowed_ipv6_cidr" {
  type = "list"
  default = ["::/0"]
  description = "A list of IPv6 CIDR Networks to allow ssh access to."
}

variable "allowed_security_groups" {
  type        = "list"
  default     = []
  description = "A list of Security Group ID's to allow access to."
}

variable "name" {
  default = "BASTION-VPN"
}

variable extra_tags {
  type        = "list"
  default     = []
  description = "A list of tags to associate to the bastion instance."
}
## Private AMI
variable "ami" {
  description = "NAT-VPN-SSH"
  type        = "map"

  default = {
    eu-west-1      = "ami-0dd116ac650af8830" # Ireland
    eu-west-3      = "ami-0041a5d56389da5e2" # Paris
  }
}

variable "instance_type" {
  default = "t3.micro"
}

variable "instance_volume_size_gb" {
  description = "The root volume size, in gigabytes"
  default     = "8"
}

variable "iam_instance_profile" {
  default = "s3_bastion"
}

variable "user_data_file" {
  default = "user_data.sh"
}

variable "s3_bucket_name" {
  default = "anybox-sshkey-bastion"
}

variable "enable_monitoring" {
  default = true
}

variable "ssh_user" {
  default = "ec2-user"
}

variable "enable_hourly_cron_updates" {
  default = "false"
}

variable "keys_update_frequency" {
  default = "*/5 * * * *"
}

variable "additional_user_data_script" {
  default = ""
}

variable "security_group_ids" {
  description = "Comma seperated list of security groups to apply to the bastion."
  default     = ""
}

variable "subnet_ids" {
  default     = []
  description = "A list of subnet ids"
}

variable "eip" {
  default = ""
}

variable "associate_public_ip_address" {
  default = false
}

# Clef SSH Utilisée pour l'installation
variable "key_name" {
  default = "anybox"
}

variable "apply_changes_immediately" {
  description = "Whether to apply the changes at once and recreate auto-scaling group"
  default     = false
}

variable "environnement" {
  default = "staging"  
}
