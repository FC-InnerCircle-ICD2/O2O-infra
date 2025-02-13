variable "vpc_resource" {
  description = "VPC"
}

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

variable "public_subnet_ids" {
  type        = list(string)
  description = "VPC Public Subnet Ids"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "VPC Public Subnet Ids"
}

variable "postgres_user" {
  type        = string
  description = "postgres user"
}

variable "postgres_password" {
  type        = string
  description = "postgres_password"
}

variable "s3_flyway_bucket" {
  type        = string
  description = "S3 flyway bucket"
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