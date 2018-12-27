#!/bin/bash

echo "## CREATION d'un Volume EFS ##"
aws ec2 --output text --query 'Vpcs[*].{VpcId:VpcId,CidrBlock:CidrBlock}' describe-vpcs
echo "Quel VPC-ID ?"
read VPCID


# EFS STORAGE Name
EFSNAME=EFS-staging


aws efs create-file-system \
--creation-token $EFSNAME \
--region eu-west-1


aws efs describe-file-systems \
--region eu-west-1

#FILESYSTEMID=$(aws efs describe-file-systems --output text --query 'FileSystems[*].{FileSystemId:FileSystemId,CreationToken:CreationToken}')
FILESYSTEMID=$(aws efs describe-file-systems --output text \
--query 'FileSystems[*].{FileSystemId:FileSystemId,CreationToken:CreationToken}' | grep $EFSNAME | awk '{print $2}')
echo $FILESYSTEMID > efs-id.txt

aws efs create-tags \
--file-system-id $FILESYSTEMID \
--tags Key=Name,Value=$EFSNAME \
--region eu-west-1



SUBNETID=$(aws ec2 describe-subnets --output text --filters "Name=vpc-id,Values=$VPCID" \
--query 'Subnets[*].{SubnetId:SubnetId,Name:Tags[?Key==`Name`].Value|[0]}' | grep Private | awk '{print $4}')

sleep 10

for i in $SUBNETID
do 
    aws efs create-mount-target --file-system-id $FILESYSTEMID --subnet-id $i
    sleep 5
done

## Add NFS inside security group
SECUGRPID=$(aws ec2 describe-security-groups --output text --filters "Name=vpc-id,Values=$VPCID" \
--query 'SecurityGroups[*].{GroupId:GroupId,GroupName:GroupName}' | grep default | awk '{print $1}')
VPCCIDR=$(aws ec2 --output text --query 'Vpcs[*].{VpcId:VpcId,CidrBlock:CidrBlock}' describe-vpcs | grep $VPCID | awk '{print $1}')
echo $VPCCIDR

aws ec2 authorize-security-group-ingress --group-id $SECUGRPID --protocol tcp --port 2049 --cidr $VPCCIDR

## add SSH Access
MYIP=$(curl ipecho.net/plain; echo)
aws ec2 authorize-security-group-ingress --group-id $SECUGRPID --protocol tcp --port 22 --cidr $MYIP/32
