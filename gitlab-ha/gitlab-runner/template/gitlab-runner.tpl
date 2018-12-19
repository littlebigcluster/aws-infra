mkdir -p /etc/gitlab-runner
cat > /etc/gitlab-runner/config.toml <<- EOF

${runners_config}

EOF

# Test GITLAB_CE online !

URL=${gitlab_url}
while [ `curl $URL -s -o /dev/null -w %{http_code}` -ne "302" ]; do
  printf '.'
  sleep 5
done

sleep 60

## Install Gitlab-runner & docker-machine
curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.rpm.sh | bash
yum install gitlab-runner-${gitlab_runner_version} -y

curl -L https://github.com/docker/machine/releases/download/v${docker_machine_version}/docker-machine-`uname -s`-`uname -m` >/tmp/docker-machine && \
  chmod +x /tmp/docker-machine && \
  cp /tmp/docker-machine /usr/local/bin/docker-machine && \
  ln -s /usr/local/bin/docker-machine /usr/bin/docker-machine


systemctl status gitlab-runner.service
systemctl is-enabled gitlab-runner.service
#systemctl enable gitlab-runner.service


#service gitlab-runner restart
#chkconfig gitlab-runner on


## Install docker
#yum install docker -y
#service docker start
#chkconfig docker on
#usermod -a -G docker ec2-user
#usermod -aG docker $(whoami)
#service docker stop
#service docker start



## register runner:
gitlab-runner verify --delete gitlab_runner



cat <<\EOF > /etc/gitlab-runner/register.sh
#!/bin/bash

gitlab-runner register -n \
--name "${runners_name}-spot" \
-u "${gitlab_url}" \
-r "${runners_token}" \
--executor "docker+machine" \
--tag-list "docker,aws" \
--run-untagged \
--locked="false" \
--docker-image "docker:latest" \
--cache-shared \
--limit 3 \
--machine-idle-nodes 1 \
--machine-max-builds 10 \
--cache-s3-server-address "s3-${aws_region}.amazonaws.com" \
--cache-s3-access-key "${bucket_user_access_key}" \
--cache-s3-secret-key "${bucket_user_secret_key}" \
--cache-s3-bucket-name "${bucket_name}" \
--machine-machine-driver "amazonec2" \
--machine-machine-name "runner-%s" \
--machine-machine-options amazonec2-instance-type=${runners_instance_type} \
--machine-machine-options amazonec2-region=${aws_region} \
--machine-machine-options amazonec2-vpc-id=${runners_vpc_id} \
--machine-machine-options amazonec2-subnet-id=${runners_subnet_id} \
--machine-machine-options amazonec2-private-address-only \
--machine-machine-options amazonec2-use-private-address \
--machine-machine-options amazonec2-request-spot-instance \
--machine-machine-options amazonec2-spot-price=${runners_spot_price_bid} \
--machine-machine-options amazonec2-security-group=${runners_security_group_name} \
--machine-machine-options amazonec2-tags=environment,${environment} \
--machine-machine-options amazonec2-monitoring=${runners_monitoring} \
--machine-machine-options amazonec2-root-size=${runners_root_size} \
--machine-off-peak-timezone "${runners_off_peak_timezone}" \
--machine-off-peak-idle-count "${runners_off_peak_idle_count}" \
--machine-off-peak-idle-time "${runners_off_peak_idle_time}"

EOF

chmod +x /etc/gitlab-runner/register.sh

/etc/gitlab-runner/register.sh
