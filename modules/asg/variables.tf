variable "aws_key_pair" {
  description = "AWS key pair"
}

variable "aws_ami" {
  description = "AWS AMI"
}

variable "vpc_security_group" {
  description = "VPC Security Group"
}

variable "nat_1_gateway" {
  description = "NAT Gateway 1"
}

variable "nat_2_gateway" {
  description = "NAT Gateway 2"
}

variable "vpc_private_1_subnet" {
  description = "VPC Private Subnet 1"
}

variable "vpc_private_2_subnet" {
  description = "VPC Private Subnet 2"
}

variable "aws_lb_target_group" {
  description = "Load Balancer Target Group"
}