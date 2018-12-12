#!/bin/bash

plan=VPC-3AZs-VPN-`date '+%Y%m%d%H%M%S'`.plan

terraform init
terraform plan -out $plan
terraform apply $plan
