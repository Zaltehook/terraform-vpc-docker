resource "aws_iam_role" "instance_iam_role" {
    name = "instance_iam_role"
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

resource "aws_iam_instance_profile" "docker_instance_profile" {
    name = "docker_instance_profile"
    role = "instance_iam_role"
}

resource "aws_iam_role_policy" "docker_iam_role_policy" {
  name = "docker_iam_role_policy"
  role = "${aws_iam_role.instance_iam_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": ["arn:aws:s3:::${aws_s3_bucket.docker.id}"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ],
      "Resource": ["arn:aws:s3:::${aws_s3_bucket.docker.id}/*"]
    }
  ]
}
EOF
}
