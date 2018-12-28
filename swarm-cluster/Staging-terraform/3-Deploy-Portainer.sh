#!/bin/bash

aws ec2 describe-instances --output text --query "Reservations[].Instances[].[Placement.AvailabilityZone,InstanceId,InstanceType,State.Name,PrivateIpAddress]" \
--filters "Name=tag:Name,Values=SwarmManager-staging"  --output table

MANAGERIP=$(aws ec2 describe-instances --output text --query "Reservations[].Instances[].[Placement.AvailabilityZone,InstanceId,InstanceType,State.Name,PrivateIpAddress]" \
--filters "Name=tag:Name,Values=SwarmManager-staging" | grep running | awk 'NR==1{print $5}')

scp -i ~/.ec2/anybox.pem -o IdentitiesOnly=yes -r PORTAINER admin@$MANAGERIP:/efs/

ssh -i ~/.ec2/anybox.pem -o IdentitiesOnly=yes admin@$MANAGERIP "mkdir /efs/PORTAINER/portainer_data"

ssh -i ~/.ec2/anybox.pem -o IdentitiesOnly=yes admin@$MANAGERIP "cd /efs/PORTAINER && docker stack deploy -c portainer-agent-stack.yml portainer"