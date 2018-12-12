#!/bin/bash
###########################################################
#
# This script checks environment and destroy all
# resources
#
###########################################################

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



# Define dummy password to avoid been prompted by terraform
export TF_VAR_postgres_gitlab_pass="somevalue"


# terraform destroy
terraform destroy --force

