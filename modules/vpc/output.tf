output "vpc_resource" {
  value = aws_vpc.MyVPC08
}

output "vpc_security_group" {
  value = aws_security_group.MySecurityGroup
}

output "vpc_public_1_subnet" {
  value = aws_subnet.MyPublic1Subnet
}

output "vpc_public_2_subnet" {
  value = aws_subnet.MyPublic2Subnet
}