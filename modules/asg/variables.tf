variable "aws_key_pair" {
  description = "AWS key pair"
}

variable "aws_ami" {
  description = "AWS AMI"
}

variable "vpc_security_group" {
  description = "VPC Security Group"
}

variable "private_subnet_ids" {
  type = list(string)
  description = "VPC Private Subnet Ids"
}

variable "alb_target_group" {
  description = "Application Load Balencer Target Group"
}