variable "key_pair" {
  description = "AWS key pair"
}

variable "ami" {
  description = "AWS AMI"
}

variable "vpc_security_group" {
  description = "VPC Security Group"
}

variable "public_subnet_ids" {
  type = list(string)
  description = "VPC Public Subnet Ids"
}