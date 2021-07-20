resource "aws_iam_role" "aws_config_role" {
  name = "aws-config-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "config.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": "AWSConfigAssumeRolePolicy"
    }
  ]
}
POLICY
}

resource "aws_iam_policy_attachment" "aws_config_policy" {
  name       = "aws-config-policy"
  roles      = ["${aws_iam_role.aws_config_role.name}"]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
}

data "aws_iam_policy_document" "aws_config_s3_access" {
  statement {
    sid = "AWSConfigBucketPutObject"

    effect = "Allow"

    actions = [
      "s3:PutObject",
    ]

    resources = [
      "${aws_s3_bucket.aws_config_bucket.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/Config/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"

      values = [
        "bucket-owner-full-control",
      ]
    }
  }

  statement {
    sid = "AWSConfigGetBucketAcl"

    effect = "Allow"

    actions = [
      "s3:GetBucketAcl",
    ]

    resources = [
      "${aws_s3_bucket.aws_config_bucket.arn}",
    ]
  }
}

resource "aws_iam_policy" "aws_config_s3_access_policy" {
  name        = "aws-config-s3-access-policy"
  description = "IAM Policy to allow AWS Config Role to access AWS Config S3 bucket"

  policy = "${data.aws_iam_policy_document.aws_config_s3_access.json}"
}

resource "aws_iam_policy_attachment" "aws_config_s3_access_policy_attachment" {
  name       = "aws-config-s3-access-policy-attachment"
  roles      = ["${aws_iam_role.aws_config_role.name}"]
  policy_arn = "${aws_iam_policy.aws_config_s3_access_policy.arn}"
}
