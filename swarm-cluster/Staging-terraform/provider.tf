provider "aws" {
  region = "${var.aws_region}"
  //skip_region_validation = true
}

terraform {
  backend "s3" {
    bucket = "anybox-terraform"
    key    = "swarm-staging"
    region = "eu-west-1"
  }
}