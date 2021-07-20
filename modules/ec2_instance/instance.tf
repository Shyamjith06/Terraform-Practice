resource "aws_instance" "i" {
   // instance_name = var.name
    instance_type = var.type
    ami = var.ami_name
    subnet_id = var.subnet_ids
    vpc_security_group_ids     = var.security_group_ids
    iam_instance_profile        = var.iam_instance_profile
    provisioner "local-exec" {
    command = "sleep 5"
  }

}
