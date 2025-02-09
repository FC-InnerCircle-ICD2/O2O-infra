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
resource "aws_vpc" "MyVPC04" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "MyVPC04"
  }
}

# Internet Gateway를 생성합니다.
resource "aws_internet_gateway" "MyIGW" {
  vpc_id = aws_vpc.MyVPC04.id

  tags = {
    Name = "MyIGW"
  }
}

# Public Subnet을 생성합니다.
resource "aws_subnet" "MyPublicSubnet" {
  vpc_id     = aws_vpc.MyVPC04.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "MyPublicSubnet"
  }
}

# Route Table을 생성합니다.
resource "aws_route_table" "MyPublicRouting" {
  depends_on = [ aws_internet_gateway.MyIGW ]
  vpc_id = aws_vpc.MyVPC04.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.MyIGW.id
  }

  tags = {
    Name = "MyPublicRouting"
  }
}

# Route Table과 Subnet을 연결합니다.
resource "aws_route_table_association" "MyPublicRouteTableAssociation" {
  subnet_id      = aws_subnet.MyPublicSubnet.id
  route_table_id = aws_route_table.MyPublicRouting.id
}

# Security Group을 생성합니다.
resource "aws_security_group" "MyPublicSecurityGroup" {
  name = "MyPublicSecurityGroup"
  description = "Permit HTTP(80), HTTPS(443) and SSH(22)"
  vpc_id = aws_vpc.MyVPC04.id

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
    Name = "MyPublicSecurityGroup"
  }
}

# private address를 생성합니다.
resource "aws_network_interface" "MyWebPrivateAddress" {
  subnet_id       = aws_subnet.MyPublicSubnet.id
  private_ips     = ["10.0.0.101"]
  security_groups = [aws_security_group.MyPublicSecurityGroup.id]

  tags = {
    Name = "MyWebPrivateAddress"
  }
}

# EC2 인스턴스를 생성합니다.
resource "aws_instance" "MyWeb" {
  depends_on = [ aws_internet_gateway.MyIGW ]
  ami           = data.aws_ami.LatestAmi.id
  instance_type = "t3.micro"
  key_name = aws_key_pair.tf_keypair.key_name

  network_interface {
    network_interface_id = aws_network_interface.MyWebPrivateAddress.id
    device_index         = 0
  }

  tags = {
    Name = "MyWeb"
  }
}