
############################
# EFS: Will provide a NFS(file sharing) service to store common files and repo
############################
resource "aws_efs_file_system" "gitlab_efs" {
  creation_token = "gitlab_efs_001"

  tags {
    Name = "gitlab_efs"
    User = "anybox"
  }
  # lifecycle {
  #   prevent_destroy = true
  # }
}

resource "aws_efs_mount_target" "gitlab_efs_mt" {
  count = "${var.efs_mt_count}"
  file_system_id = "${aws_efs_file_system.gitlab_efs.id}"
  subnet_id      = "${element(var.subnet_idz,count.index)}"
  # subnet_id      = "${element(aws_subnet.net-gitlab-private.*.id,count.index)}"
  security_groups = ["${aws_security_group.sg_gitlab_public.id}", "${aws_security_group.sg_gitlab_private.id}"]
}