output "vpc_resource" {
  value = aws_vpc.MyVPC08
}

output "aws_key_pair" {
  value = data.aws_key_pair.tf_keypair
}

output "aws_ami" {
  value = data.aws_ami.LatestAmi
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

output "nat_1_gateway" {
  value = aws_nat_gateway.MyNatGW1
}

output "nat_2_gateway" {
  value = aws_nat_gateway.MyNatGW2
}

output "vpc_private_1_subnet" {
  value = aws_subnet.MyPrivate1Subnet
}

output "vpc_private_2_subnet" {
  value = aws_subnet.MyPrivate2Subnet
}