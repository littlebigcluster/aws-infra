terraform {
  required_version = ">= 0.10.3" # introduction of Local Values configuration language feature
}

provider "aws" {
  region = "${var.region}"
}

## VPC
# https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/1.46.0
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
    Environment = "staging"
  }
}


# Definition of IAM instance profile which is allowed to read-only from S3.
resource "aws_iam_instance_profile" "s3_bastion" {
  name = "${var.iam_instance_profile}"
  role = "${aws_iam_role.s3_bastion.name}"
}

resource "aws_iam_role" "s3_bastion" {
  name = "${var.iam_instance_profile}"
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

resource "aws_iam_role_policy" "s3_bastion_policy" {
  name = "s3_bastion-policy"
  role = "${aws_iam_role.s3_bastion.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "s3:PutAccountPublicAccessBlock",
                "s3:GetAccountPublicAccessBlock",
                "s3:ListAllMyBuckets",
                "s3:HeadBucket"
            ],
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": [
              "arn:aws:s3:::${var.s3_bucket_name}/*",
              "arn:aws:s3:::${var.s3_bucket_name}"  
            ]         
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "ec2_bastion_policy" {
  name = "ec2_bastion-policy"
  role = "${aws_iam_role.s3_bastion.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1425916919000",
            "Effect": "Allow",
            "Action": [
                "ec2:AssociateAddress"
            ],
            "Resource": ["*"]
        }
    ]
}
EOF
}



resource "aws_s3_bucket" "s3_bucket" {
  bucket = "${var.s3_bucket_name}"
  acl    = "private"

  tags {
    Name        = "bastion-bucket"
    Environment = "ANYBOX"
  }
}
