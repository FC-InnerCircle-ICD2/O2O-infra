variable "key_pair" {
  description = "AWS key pair"
}

variable "ami" {
  description = "AWS AMI"
}

variable "vpc_security_group" {
  description = "VPC Security Group"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "VPC Private Subnet Ids"
}

variable "alb_target_group" {
  description = "Application Load Balencer Target Group"
}

variable "s3_frontend_shop_bucket" {
  type        = string
  description = "frontend shop bucket"
}

variable "aws_access_key_id" {
  description = "aws access key id"
}

variable "aws_secret_access_key" {
  description = "aws secret access key"
}

variable "aws_default_region" {
  description = "aws default region"
}