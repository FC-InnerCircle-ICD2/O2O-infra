output "vpc_resource" {
  value = aws_vpc.prod
}

output "key_pair" {
  value = data.aws_key_pair.tf_keypair
}

output "ami" {
  value = data.aws_ami.LatestAmi
}

output "security_group" {
  value = aws_security_group.sg
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "nat_gateway" {
  value = aws_nat_gateway.nat[*]
}