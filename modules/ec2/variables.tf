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