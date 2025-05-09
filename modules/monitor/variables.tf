variable "key_pair" {
  description = "AWS key pair"
}

variable "ami" {
  description = "AWS AMI"
}

variable "vpc_security_group" {
  description = "VPC Security Group"
}

variable "availability_zones" {
  description = "Availability Zones"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "VPC Public Subnet Ids"
}

variable "alb_target_group" {
  description = "Application Load Balencer Target Group"
}

variable "s3_backend_bucket" {
  type        = string
  description = "S3 backend bucket"
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

variable "ec2_instance_profile" {
  description = "ec2 profile"
}

variable "gf_security_admin_user" {
  description = "gf security admin user"
}

variable "gf_security_admin_password" {
  description = "gf security admin password"
}

variable "grafana_root_url" {
  description = "grafana root url"
}