resource "aws_iam_instance_profile" "swarm_cluster_profile" {
  name    = "swarm-cluster-staging-profile"
  role   = "${aws_iam_role.swarm_cluster_role.name}"
}

resource "aws_iam_role_policy" "swarm_cluster_policy" {
  name = "swarm-cluster-staging-policy"
  role = "${aws_iam_role.swarm_cluster_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:Describe*",
        "ec2:CreateTags"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "registry-ecr" {
  name = "registry-ecr"
  role = "${aws_iam_role.swarm_cluster_role.id}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "ecr:*",
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "AmazonS3FullAccess" {
  name = "AmazonS3FullAccess"
  role = "${aws_iam_role.swarm_cluster_role.id}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": "*"
        }
    ]
}
EOF
}



resource "aws_iam_role" "swarm_cluster_role" {
  name = "swarm-cluster-staging-role"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}

EOF
}
