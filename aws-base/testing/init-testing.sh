#!/bin/bash

plan=VPC-TESTING-3AZs-VPN-`date '+%Y%m%d%H%M%S'`.plan



# Check if a given program is in PATH
check_program () {
  
if [ ! $(which $1) ]; then
   echo "$1 not found in PATH"
   exit 1
fi
}

# Check if terraform and ansible are in PATH
for I in terraform ansible 
do
  check_program "${I}"
done

read -p "Are you sure to do that ? Double check variables used in your configuration file before typing 'y'" -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]
    then
        # Lancement terraform
        terraform init
        terraform plan -out $plan
        terraform apply $plan
fi
