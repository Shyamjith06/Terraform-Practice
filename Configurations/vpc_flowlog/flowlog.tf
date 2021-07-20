resource "aws_vpc" "vpc"{
    cidr_block = "10.10.16.0/24"
    instance_tenancy = "default"

    tags = {
        name = "yoyo"
        
    }
}


resource "aws_flow_log" "vpc_flowlog-s3" {
    log_destination = "arn:aws:s3:::shyamjith1"
    log_destination_type = "s3"
    vpc_id = aws_vpc.vpc.id
    traffic_type = "ALL"

}

resource "aws_flow_log" "vpc_flowlog-cloudwatch" {
    iam_role_arn    =   "arn:aws:iam::466644029397:role/flowlogsRole"  ##  The ARN for the IAM role that's used to post flow logs to a CloudWatch Logs log group
    log_destination = "arn:aws:logs:us-east-2:466644029397:log-group:/aws/lambda/shyam:*"   ##arn of cloudwatch log group
    vpc_id = aws_vpc.vpc.id
    traffic_type = "ALL"

}
