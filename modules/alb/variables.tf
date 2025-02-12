variable "vpc_resource" {
  description = "VPC"
}

variable "vpc_security_group" {
  description = "VPC Security Group"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "VPC Public Subnet Ids"
}