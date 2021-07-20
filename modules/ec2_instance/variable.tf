variable "name" {
}
variable "iam_instance_profile" {
}
variable "type" {
}
variable "public_ip" {
  default = false
}
variable "security_group_ids" {
  type = list(string)
}
variable "subnet_ids" {

}
variable "vpc" {
  default = "digital_platform"
}

variable "ami_name" {
}
