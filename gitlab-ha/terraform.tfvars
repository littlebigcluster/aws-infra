aws_region = "eu-west-1"
efs_mt_count = "3"
postgres_instance = "db.t2.micro"
postgres_gitlab_dbname = "gitlabhq_production"
postgres_gitlab_user = "git"
elasticache_type = "cache.t2.micro"
elasticache_parameter_group = "default.redis3.2"
seed_instance_type = "t3.medium"
gitlab_instance_type = "t3.medium"
seed_ami = "ami-02fc24d56bc5f3d67"
ami_id = "GITLAB-CE"
gitlab_instances_max = "1"
gitlab_instances_min = "1"
autoscaling_capacity = "1"
autoscaling_check_grace = "120"
autoscaling_check_type = "ELB"
cache_bucket_prefix = "gitlab-cache"
docker_machine_instance_type = "m5.large"
docker_machine_version = "0.16.0"
gitlab_runner_version = "11.5.1"
key_name = "anybox"