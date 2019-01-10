#####################################################
# Elasticache redis: Redis is used by Gitlab to store Jobs
####################################################
resource "aws_elasticache_cluster" "gitlab-redis" {
  cluster_id           = "gitlab-redis-001"
  engine               = "redis"
  engine_version       = "3.2.10"
  node_type            = "${var.elasticache_type}"
  port                 = 6379
  num_cache_nodes      = 1
  parameter_group_name = "${var.elasticache_parameter_group}"
  subnet_group_name    = "${aws_elasticache_subnet_group.redis_net_group.name}"
  security_group_ids   = ["${aws_security_group.sg_gitlab_redis.id}"]
  tags {
    Name = "gitlab-redis"
    User = "anybox"
  }
}
