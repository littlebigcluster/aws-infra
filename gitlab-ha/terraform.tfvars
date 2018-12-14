aws_region = "eu-west-1"
efs_mt_count = "3"
postgres_instance = "db.t2.micro"
postgres_gitlab_dbname = "gitlabhq_production"
postgres_gitlab_user = "git"
elasticache_type = "cache.t2.micro"
elasticache_parameter_group = "default.redis3.2"
seed_instance_type = "t3.medium"
gitlab_instance_type = "t2.medium"
seed_ami = "ami-02fc24d56bc5f3d67"
ami_id = "GITLAB-CE"
gitlab_instances_max = "2"
gitlab_instances_min = "2"
autoscaling_capacity = "2"
autoscaling_check_grace = "120"
autoscaling_check_type = "ELB"
