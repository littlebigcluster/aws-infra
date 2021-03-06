#!/bin/bash

echo "UPDATE AMI ..."

# AMIMANAGER=$(cat "../Staging-packer/ami-manager.txt")
# AMIWORKER=$(cat "../Staging-packer/ami-worker.txt")

AMIMANAGER=$(aws ec2 describe-images --owners 972087677911 --filters 'Name=name,Values=docker-manager-staging*' 'Name=state,Values=available' | jq -r '.Images | sort_by(.CreationDate) | last(.[]).ImageId')
AMIWORKER=$(aws ec2 describe-images --owners 972087677911 --filters 'Name=name,Values=docker-worker-staging*' 'Name=state,Values=available' | jq -r '.Images | sort_by(.CreationDate) | last(.[]).ImageId')

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

plan=cluster-swarm-staging-`date '+%Y%m%d%H%M%S'`.plan

# Lancement Cluster SWARM
terraform init
terraform plan --out $plan
terraform apply $plan