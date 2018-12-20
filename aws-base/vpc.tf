terraform {
  required_version = ">= 0.10.3" # introduction of Local Values configuration language feature
}

provider "aws" {
  region = "${var.region}"
}

## VPC
module "my-vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.vpc_name}"
  cidr = "${var.vpc_cidr}"

  azs             = ["${var.aws_az}"]
  private_subnets = ["${var.subnet_priv}"]
  public_subnets  = ["${var.subnet_pub}"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  reuse_nat_ips        = false
  enable_vpn_gateway   = false
  enable_dns_hostnames = true
  enable_s3_endpoint   = true

  enable_dhcp_options              = true
  dhcp_options_domain_name         = "${var.region}.compute.internal"
  # dhcp_options_domain_name_servers = ["127.0.0.1", "10.1.0.2"]

  tags = {
    Terraform   = "true"
    Owner       = "ANYBOX"
    Environment = "${var.environnement}"
  }
}

