#!/bin/bash

echo "UPDATE AMI ..."

AMIMANAGER=$(cat "../Staging-packer/ami-manager.txt")
AMIWORKER=$(cat "../Staging-packer/ami-worker.txt")

cp variables-template variables.tf
sed -i s/AMI-MANAGER/$AMIMANAGER/ variables.tf
sed -i s/AMI-WORKER/$AMIWORKER/ variables.tf



echo "QUEL VPC ?"
aws ec2 --output text --query 'Vpcs[*].{VpcId:VpcId,CidrBlock:CidrBlock}' describe-vpcs
echo "choix:"
read VPCID
sed -i s/VPCID/$VPCID/ variables.tf

VPCCIDR=$(aws ec2 --output text --query 'Vpcs[*].{VpcId:VpcId,CidrBlock:CidrBlock}' describe-vpcs | grep $VPCID | awk '{print $1}')
echo $VPCCIDR
VPCCIDR=`echo "${VPCCIDR}" | sed 's:/:\\\/:g'`
sed -i s/VPCCIDR/$VPCCIDR/ variables.tf



echo ""
echo "Alimentation des subnets publics"
aws ec2 describe-subnets --output text --filters "Name=vpc-id,Values=$VPCID" \
--query 'Subnets[*].{SubnetId:SubnetId,Name:Tags[?Key==`Name`].Value|[0],CidrBlock:CidrBlock}' | grep public | awk  '{print $3}' > SUBNETPUB.txt
SUBNETPUB=$(sed 's/.*/"&"/' SUBNETPUB.txt | paste -sd, -)

echo $SUBNETPUB
sed -i s/SUBNETPUB/$SUBNETPUB/ variables.tf




echo ""
echo "Alimentation des subnets privés"
aws ec2 describe-subnets --output text --filters "Name=vpc-id,Values=$VPCID" \
--query 'Subnets[*].{SubnetId:SubnetId,Name:Tags[?Key==`Name`].Value|[0],CidrBlock:CidrBlock}' | grep private | awk  '{print $3}' > SUBNETPRIV.txt
SUBNETPRIV=$(sed 's/.*/"&"/' SUBNETPRIV.txt | paste -sd, -)

echo $SUBNETPRIV
sed -i s/SUBNETPRIV/$SUBNETPRIV/ variables.tf

plan=gitlab-HA-`date '+%Y%m%d%H%M%S'`.plan

# Lancement Cluster SWARM
terraform init
terraform plan $plan
terraform apply $plan