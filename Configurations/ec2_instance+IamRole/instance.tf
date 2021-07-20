module "ec2-instance" {
    source = "../../module/ec2_instance"
    name = "roles-test-instance_type"
    iam_instance_profile = aws_iam_instance_profile.test_profile.name
    public_ip = "true"
    security_group_ids = ["sg-962516e3"]
    ami_name = "ami-00399ec92321828f5"
    subnet_ids = "subnet-1b530257"
    type = "t2.micro"
}

resource "aws_iam_instance_profile" "test_profile" {
  name = "test_profile"
  role = aws_iam_role.role.name
}

resource "aws_iam_role" "role" {
  name = "test_role"
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
