resource "aws_iam_policy" "aws_config_ec2_regions_restriction_policy" {
  name        = "aws-config-ec2-regions-restriction-policy"
  path        = "/"
  description = "Policy for restricting access to ec2 outside eu-west-1 and eu-west-2"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "ec2:*",
      "Resource": "*",
      "Effect": "Deny",
      "Condition": {
        "StringNotEquals": {
          "ec2:Region": [
            "eu-west-1",
            "eu-west-2"
          ]
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "aws_config_ec2_regions_restriction_policy_attachment" {
  policy_arn = "${aws_iam_policy.aws_config_ec2_regions_restriction_policy.arn}"
  role       = "${element(split("/", lookup(var.saml_admin_role_arns, terraform.workspace)), 1)}"
}

resource "aws_iam_policy" "aws_config_ec2_instance_type_restriction_policy" {
  name        = "aws-config-ec2-instance-type-restriction-policy"
  path        = "/"
  description = "Policy for restricting access to ec2 based on the used instance types"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "ec2:RunInstances",
      "Resource": "arn:aws:ec2:*:*:instance/*",
      "Effect": "Deny",
      "Condition": {
        "ForAnyValue:StringNotLike": {
          "ec2:InstanceType": [
            "m4.2xlarge",
            "m4.large",
            "m4.xlarge",
            "m5.12xlarge",
            "m5.2xlarge",
            "m5.4xlarge",
            "m5.8xlarge",
            "m5.large",
            "m5.xlarge",
            "m5a.2xlarge",
            "mq.m5.large",
            "mq.m5.xlarge",
            "r5.2xlarge",
            "r5.4xlarge",
            "r5.large",
            "r5a.2xlarge",
            "r5a.4xlarge",
            "r5a.large",
            "r5a.xlarge",
            "t2.medium",
            "t2.micro",
            "t2.nano",
            "t2.small",
            "t3.2xlarge",
            "t3.large",
            "t3.medium",
            "t3.micro",
            "t3.nano",
            "t3.small",
            "t3.xlarge",
            "t3a.2xlarge",
            "t3a.nano"
          ]
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "aws_config_ec2_instance_type_restriction_policy_attachment" {
  policy_arn = "${aws_iam_policy.aws_config_ec2_instance_type_restriction_policy.arn}"
  role       = "${element(split("/", lookup(var.saml_admin_role_arns, terraform.workspace)), 1)}"
}
