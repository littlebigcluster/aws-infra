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
    echo "Switch to 'testing' workspace"
    workspace_exist=$(terraform workspace select testing 2>&1)
    # Partial comparison
    if [[ "$workspace_exist" == *"doesn't exist"* ]]
    then
        echo "Workspace 'testing' does not exist, exiting."
        exit 1
    fi
    terraform destroy
fi
