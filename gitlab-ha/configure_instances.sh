#!/bin/bash

RDS_HOST=$(echo -n "${RDS_ENDPOINT}" | cut -d: -f1)
export ANSIBLE_HOST_KEY_CHECKING="False"
export ANSIBLE_SSH_ARGS='-o IdentitiesOnly=yes \
-o StrictHostKeyChecking=no \
-o UserKnownHostsFile=/dev/null \
-o AddKeysToAgent=no'


# Create ansible hosts file

cat <<EOF > hosts
[gitlab-server]
gitlab01 ansible_host=${INSTANCE_IP} ansible_user=admin ansible_python_interpreter=/usr/bin/python3
EOF

echo 
# Check if node is up and running
for((I=0;$I<30;I=$I+1))
do
ansible gitlab-server -m raw -a "id" -i hosts  --private-key "${KEYPAIR}" >/dev/null 2>&1 
if [ $? -eq 0 ]; then
  break
fi
sleep 10
done 

# Configure Instance

ansible-playbook -i hosts --private-key "${KEYPAIR}" site.yml \
--extra-vars "full_qualified_name_ssh=${FQN_DOMAIN_SSH} \
full_qualified_name=${FQN_DOMAIN} \
full_qualified_name_registry=${FQN_DOMAIN_REGISTRY} \
postgres_host=${RDS_HOST} \
postgres_gitlab_pass=${RDS_PASS} \
smtp_password=${SMTP_PASS} \
ldap_password=${LDAP_PASS} \
redis_host=${REDIS_ENDPOINT} \
gitlab_root_password=${GITLABROOT_PASS} \
s3_backup_bucket=${S3_BUCKET} \
runner_token=${RUNNER_TOKEN} \
efs_dnsname=${EFS}"
