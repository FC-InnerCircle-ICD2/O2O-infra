provider "aws" {
  region = "ap-northeast-2"
}

# key를 생성합니다.
resource "aws_key_pair" "tf_keypair" {
  key_name = "tf_keypair"
  public_key = file("C:\\sshkey\\tf_keypair.pub")

  tags = {
    Name = "tf_keypair"
  }
}

# ami 를 생성합니다.
data "aws_ami" "LatestAmi" {
  most_recent = true
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }

  owners = ["amazon"]
}

# VPC를 생성합니다.
resource "aws_vpc" "MyVPC08" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "MyVPC08"
  }
}

# Internet Gateway를 생성합니다.
resource "aws_internet_gateway" "MyIGW" {
  vpc_id = aws_vpc.MyVPC08.id

  tags = {
    Name = "MyIGW"
  }
}

# Public Subnet을 생성합니다.
resource "aws_subnet" "MyPublic1Subnet" {
  vpc_id     = aws_vpc.MyVPC08.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "MyPublic1Subnet"
  }
}

# Public Subnet을 생성합니다.
resource "aws_subnet" "MyPublic2Subnet" {
  vpc_id     = aws_vpc.MyVPC08.id
  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "MyPublic2Subnet"
  }
}

# Route Table을 생성합니다.
resource "aws_route_table" "MyPublic1Routing" {
  depends_on = [ aws_internet_gateway.MyIGW ]
  vpc_id = aws_vpc.MyVPC08.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.MyIGW.id
  }

  tags = {
    Name = "MyPublic1Routing"
  }
}

# Route Table을 생성합니다.
resource "aws_route_table" "MyPublic2Routing" {
  depends_on = [ aws_internet_gateway.MyIGW ]
  vpc_id = aws_vpc.MyVPC08.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.MyIGW.id
  }

  tags = {
    Name = "MyPublic2Routing"
  }
}

# Route Table과 Subnet을 연결합니다.
resource "aws_route_table_association" "MyPublic1RouteTableAssociation" {
  subnet_id      = aws_subnet.MyPublic1Subnet.id
  route_table_id = aws_route_table.MyPublic1Routing.id
}

# Route Table과 Subnet을 연결합니다.
resource "aws_route_table_association" "MyPublic2RouteTableAssociation" {
  subnet_id      = aws_subnet.MyPublic2Subnet.id
  route_table_id = aws_route_table.MyPublic2Routing.id
}

# EIP를 생성합니다.
resource "aws_eip" "MyNatGW1EIP" {
  domain   = "vpc"

  lifecycle {
    create_before_destroy = true
  }
}

# EIP를 생성합니다.
resource "aws_eip" "MyNatGW2EIP" {
  domain   = "vpc"

  lifecycle {
    create_before_destroy = true
  }
}

# Nat Gateway를 생성합니다.
resource "aws_nat_gateway" "MyNatGW1" {
  depends_on = [aws_internet_gateway.MyIGW]
  allocation_id = aws_eip.MyNatGW1EIP.id
  subnet_id     = aws_subnet.MyPublic1Subnet.id

  tags = {
    Name = "MyNatGW1"
  }
}

# Nat Gateway를 생성합니다.
resource "aws_nat_gateway" "MyNatGW2" {
  depends_on = [aws_internet_gateway.MyIGW]
  allocation_id = aws_eip.MyNatGW2EIP.id
  subnet_id     = aws_subnet.MyPublic2Subnet.id

  tags = {
    Name = "MyNatGW2"
  }
}

# Private Subnet을 생성합니다.
resource "aws_subnet" "MyPrivate1Subnet" {
  vpc_id     = aws_vpc.MyVPC08.id
  cidr_block = "10.0.100.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "MyPrivate1Subnet"
  }
}

# Private Subnet을 생성합니다.
resource "aws_subnet" "MyPrivate2Subnet" {
  vpc_id     = aws_vpc.MyVPC08.id
  cidr_block = "10.0.200.0/24"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "MyPrivate2Subnet"
  }
}

# Route Table을 생성합니다.
resource "aws_route_table" "MyPrivate1Routing" {
  depends_on = [ aws_nat_gateway.MyNatGW1 ]
  vpc_id = aws_vpc.MyVPC08.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.MyNatGW1.id
  }

  tags = {
    Name = "MyPrivate1Routing"
  }
}

# Route Table을 생성합니다.
resource "aws_route_table" "MyPrivate2Routing" {
  depends_on = [ aws_nat_gateway.MyNatGW2 ]
  vpc_id = aws_vpc.MyVPC08.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.MyNatGW2.id
  }

  tags = {
    Name = "MyPrivate2Routing"
  }
}

# Route Table과 Subnet을 연결합니다.
resource "aws_route_table_association" "MyPrivate1RouteTableAssociation" {
  subnet_id      = aws_subnet.MyPrivate1Subnet.id
  route_table_id = aws_route_table.MyPrivate1Routing.id
}

# Route Table과 Subnet을 연결합니다.
resource "aws_route_table_association" "MyPrivate2RouteTableAssociation" {
  subnet_id      = aws_subnet.MyPrivate2Subnet.id
  route_table_id = aws_route_table.MyPrivate2Routing.id
}

# Security Group을 생성합니다.
resource "aws_security_group" "MySecurityGroup" {
  name = "MySecurityGroup"
  description = "Permit HTTP(80), HTTPS(443) and SSH(22)"
  vpc_id = aws_vpc.MyVPC08.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"  # -1 인 경우 모든 트래픽
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "MySecurityGroup"
  }
}