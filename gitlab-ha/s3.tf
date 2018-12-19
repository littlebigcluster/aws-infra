# resources to AWS S3 gitlab backup
# This is just a sample definition of IAM instance profile which is allowed to backup to S3.
resource "aws_iam_instance_profile" "s3_gitlab_backup" {
  name = "s3_gitlab_backup"
  role = "${aws_iam_role.s3_gitlab_backup.name}"
}

resource "aws_iam_role" "s3_gitlab_backup" {
  name = "s3_gitlab_backup"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "s3_gitlab_backup_policy" {
  name = "s3_gitlab_backup-policy"
  role = "${aws_iam_role.s3_gitlab_backup.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": ["s3:ListBucket"],
            "Resource": ["arn:aws:s3:::${var.s3_backup_bucket}"]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject"
            ],
            "Resource": ["arn:aws:s3:::${var.s3_backup_bucket}/*"]
        }
    ]
}
EOF
}

resource "aws_s3_bucket" "s3-gitlab-backup" {
  bucket = "${var.s3_backup_bucket}"
  acl    = "private"

  tags {
    Name        = "${var.s3_backup_bucket}"
    Environment = "Backup"
  }
  # We explicitly prevent destruction using terraform. Remove this only if you really know what you're doing.
  lifecycle {
    # prevent_destroy = true
  }
  versioning {
    enabled = true
  }
  lifecycle_rule {
    id      = "remove_after_70d"
    enabled = true
    expiration {
      days = 70
    }
  }
}