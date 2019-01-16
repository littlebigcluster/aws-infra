#!/bin/bash

source .env

# Check if a given program is in PATH
check_program () {
  
if [ ! $(which $1) ]; then
   echo "$1 not found in PATH"
   exit 1
fi
}

# Check if terraform, ansible and openssl are in PATH
for I in terraform ansible openssl 
do
  check_program "${I}"
done


plan=gitlab-HA-`date '+%Y%m%d%H%M%S'`.plan

read -p "Are you sure to do that ? Double check variables used in your configuration file before typing 'y'" -r
if [[ $REPLY =~ ^[Yy]$ ]]
then

    ## Config variables.tf 
    cp variables.template variables.tf

    echo "Sur quel VPC déployer ?"
    aws ec2 describe-vpcs --output text --query 'Vpcs[*].{VpcId:VpcId,CidrBlock:CidrBlock}' 
    echo "choix id:"
    read VPCID
    sed -i s/VPCID/$VPCID/ variables.tf

    echo ""
    echo "### Alimentation des subnets ID publics"
    aws ec2 describe-subnets --output text --filters "Name=vpc-id,Values=$VPCID" --query 'Subnets[*].{SubnetId:SubnetId,Name:Tags[?Key==`Name`].Value|[0],CidrBlock:CidrBlock}' | grep public | awk  '{print $3}' > SUBNETPUB.txt
    SUBNETPUB=$(sed 's/.*/"&"/' SUBNETPUB.txt | paste -sd, -)

    echo $SUBNETPUB
    sed -i s/SUBNETPUB/$SUBNETPUB/ variables.tf

    echo ""
    echo "### Alimentation des subnets ID privés"
    aws ec2 describe-subnets --output text --filters "Name=vpc-id,Values=$VPCID" --query 'Subnets[*].{SubnetId:SubnetId,Name:Tags[?Key==`Name`].Value|[0],CidrBlock:CidrBlock}' | grep private | awk  '{print $3}' > SUBNETPRIV.txt
    SUBNETPRIV=$(sed 's/.*/"&"/' SUBNETPRIV.txt | paste -sd, -)

    echo $SUBNETPRIV
    sed -i s/SUBNETPRIV/$SUBNETPRIV/ variables.tf

    echo ""
    echo "### VPC - cidr"
    VPC_CIDR=`aws ec2 describe-vpcs --output text --filters "Name=vpc-id,Values=$VPCID" --query 'Vpcs[*].{CidrBlock:CidrBlock}'`
    echo $VPC_CIDR

    sed -i s~VPC_CIDR~$VPC_CIDR~ variables.tf


    # # ldap Anybox Password
    # echo "LDAP paswword Anybox ?"
    # read -n LDAPPASS
    # export TF_VAR_ldap_password=$LDAPPASS

    # # Aleatoire PostgreSQL Password
    # export TF_VAR_postgres_gitlab_pass=$(openssl rand -base64 20 | sed 's/\///g')

    ### TERRAFORM lancement
    echo "Create 'testing' workspace or switch if it already exists"
    workspace_exist=$(terraform workspace new testing 2>&1)
    # Partial comparison
    if [[ "$workspace_exist" == *"already exists"* ]]
    then
        terraform workspace select testing
    fi
    terraform init -backend-config=backend_config_testing
    terraform plan -out $plan
    terraform apply $plan

    # Destroy gitlab-seed instance
    INSTANCE_ID=$(aws ec2 describe-instances --output text --filters "Name=tag:Name,Values=gitlab-seed" "Name=instance-state-name,Values=running" --query "Reservations[*].Instances[*].[InstanceId]")
    aws ec2 terminate-instances --instance-ids $INSTANCE_ID > /dev/null
    echo "Instance seed $INSTANCE_ID destroyed ..."
fi
