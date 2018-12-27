#!/bin/bash

aws ec2 describe-instances --output text --query "Reservations[].Instances[].[Placement.AvailabilityZone,InstanceId,InstanceType,State.Name,PrivateIpAddress]" \
--filters "Name=tag:Name,Values=SwarmManager-staging"  --output table

MANAGERIP=$(aws ec2 describe-instances --output text --query "Reservations[].Instances[].[Placement.AvailabilityZone,InstanceId,InstanceType,State.Name,PrivateIpAddress]" \
--filters "Name=tag:Name,Values=SwarmManager-staging" | grep running | awk 'NR==1{print $5}')

scp -i ~/.ec2/anybox.pem -o IdentitiesOnly=yes -r TRAEFIK admin@$MANAGERIP:/efs/


ssh -i ~/.ec2/anybox.pem -o IdentitiesOnly=yes admin@$MANAGERIP "cd /efs/TRAEFIK && docker stack deploy -c docker-compose.yml traefik"