resource "aws_iam_role" "test-role-2" {
    name = "test-role"
    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": 
    {
        "Effect": "Deny",
        "Action": "sts:AssumeRole",
        "Principal": {
            "Service": "ec2.amazonaws.com"
        }
    }
}
EOF
}
resource "aws_iam_policy" "test-policy" {
    name = "test-policy"
    description = "test-role and policy"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:Describe*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "test-attachment"{
    name = "test-policy-attachment"
    roles = ["${aws_iam_role.test-role-2.name}"]
    policy_arn = "${aws_iam_policy.test-policy.arn}"
}






