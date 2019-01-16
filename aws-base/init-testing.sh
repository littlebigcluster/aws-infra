#!/bin/bash

plan=VPC-3AZs-VPN-`date '+%Y%m%d%H%M%S'`.plan



# Check if a given program is in PATH
check_program () {
  
if [ ! $(which $1) ]; then
   echo "$1 not found in PATH"
   exit 1
fi
}

# Check if terraform are in PATH
for I in terraform ansible 
do
  check_program "${I}"
done

read -p "Are you sure to do that ? Double check variables used in your configuration file before typing 'y'" -r
if [[ $REPLY =~ ^[Yy]$ ]]
then
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
fi
