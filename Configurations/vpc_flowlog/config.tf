terraform {
    backend "s3" {
        bucket = "shyamjith1"
        key = "flowlog"
        region = "us-east-2"
    }
}
