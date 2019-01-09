
resource "aws_iam_instance_profile" "s3_bastion" {
  name = "${var.iam_instance_profile}"
  role = "${aws_iam_role.s3_bastion.name}"
}

resource "aws_iam_role" "s3_bastion" {
  name = "${var.iam_instance_profile}"
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

resource "aws_iam_role_policy" "s3_bastion_policy" {
  name = "s3_bastion-policy"
  role = "${aws_iam_role.s3_bastion.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "s3:PutAccountPublicAccessBlock",
                "s3:GetAccountPublicAccessBlock",
                "s3:ListAllMyBuckets",
                "s3:HeadBucket"
            ],
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": [
              "arn:aws:s3:::${var.s3_bucket_name}/*",
              "arn:aws:s3:::${var.s3_bucket_name}"  
            ]         
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "ec2_bastion_policy" {
  name = "ec2_bastion-policy"
  role = "${aws_iam_role.s3_bastion.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1425916919000",
            "Effect": "Allow",
            "Action": [
                "ec2:AssociateAddress"
            ],
            "Resource": ["*"]
        }
    ]
}
EOF
}



resource "aws_s3_bucket" "s3_bucket" {
  bucket = "${var.s3_bucket_name}"
  acl    = "private"

  tags {
    Name        = "bastion-bucket"
    Environment = "${var.environnement}"
  }
}