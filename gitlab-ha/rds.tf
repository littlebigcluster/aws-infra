####################################
# RDS - PostgreSQL: Main DB used by GitLab
######################################
resource "aws_db_instance" "gitlab-postgres" {
  allocated_storage	= 10
  engine		= "postgres"
  engine_version	= "9.6.11"
  instance_class	= "${var.postgres_instance}"
  multi_az = false
  name			= "${var.postgres_gitlab_dbname}"
  username		= "${var.postgres_gitlab_user}"
  password		= "${var.postgres_gitlab_pass}"
  db_subnet_group_name  = "${aws_db_subnet_group.db_net_group.name}"
  vpc_security_group_ids = ["${aws_security_group.sg_gitlab_postgresql.id}"]
  skip_final_snapshot = true
  tags {
    Name = "gitlab-postgres"
    User = "anybox"
  }
}