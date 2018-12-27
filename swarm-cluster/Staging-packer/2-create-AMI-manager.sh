#!/bin/bash

# Creation AMI Docker pour cluster SWARM sur AWS eu-central-1

# list vpc:
#aws ec2 --output text --query 'Vpcs[*].{VpcId:VpcId,Name:Tags[?Key==`Name`].Value|[0],CidrBlock:CidrBlock}' describe-vpcs
aws ec2 --output text --query 'Vpcs[*].{VpcId:VpcId,CidrBlock:CidrBlock}' describe-vpcs
echo "Quel VPC-ID ?"
read VPCID

# list public subnet:
SUBNETIDS=$(aws ec2 describe-subnets --output text --filters "Name=vpc-id,Values=$VPCID" \
--query 'Subnets[*].{SubnetId:SubnetId,Name:Tags[?Key==`Name`].Value|[0],CidrBlock:CidrBlock}' | grep public | awk '{print $3}')
SUBNETID=($(echo $SUBNETIDS | tr " " "\n"))
echo "Subnetid public: ${SUBNETID[0]}"


# list security group:
SGROUP=$(aws ec2 describe-security-groups --output text --filters "Name=vpc-id,Values=$VPCID" \
--query 'SecurityGroups[*].{GroupId:GroupId,Description:Description}' | grep "default VPC security group" | awk '{print $5}')
echo "Quel Security group ?"
echo "Security group: $SGROUP"

EFSID=$(cat "efs-id.txt")
cp docker-aws-debian-manager-TEMPLATE.json docker-aws-debian-manager.json
sed -i s/fs-XXXXXX/$EFSID/ docker-aws-debian-manager.json

packer build \
       -var aws_vpc_id=$VPCID \
       -var aws_subnet_id=${SUBNETID[0]} \
       -var aws_security_group_id=$SGROUP \
       -var aws_default_region='eu-west-1' \
       docker-aws-debian-manager.json 2>&1 | tee output-build-manager.txt

tail -2 output-build-manager.txt | head -2 | awk 'match($0, /ami-.*/) { print substr($0, RSTART, RLENGTH) }' > ami-manager.txt