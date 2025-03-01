locals {
  public_cidrs       = ["10.0.1.0/24", "10.0.2.0/24"]
  private_cidrs      = ["10.0.3.0/24", "10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["ap-northeast-2a", "ap-northeast-2c"]
}

provider "aws" {
  region = "ap-northeast-2"
}

# key를 생성합니다.
data "aws_key_pair" "tf_keypair" {
  key_name = "dev-app-01"
}

# ami 를 생성합니다.
data "aws_ami" "LatestAmi" {
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["al2023-ami-2023.6.20250203.1-kernel-6.1-x86_64"]
  }

  owners = ["amazon"]
}

# VPC를 생성합니다.
resource "aws_vpc" "prod" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "prod-vpc"
  }
}

# Security Group을 생성합니다.
resource "aws_security_group" "sg" {
  name        = "prod-sg"
  description = "Permit HTTP(80), HTTPS(443) and SSH(22)"
  vpc_id      = aws_vpc.prod.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8082
    to_port     = 8082
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8089
    to_port     = 8089
    protocol    = "tcp"
    cidr_blocks = [var.grafana_root_url]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 인 경우 모든 트래픽
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "prod-sg"
  }
}

# Internet Gateway를 생성합니다.
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.prod.id

  tags = {
    Name = "prod-igw"
  }
}

# Public Subnet을 생성합니다.
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.prod.id
  cidr_block              = local.public_cidrs[count.index]
  availability_zone       = local.availability_zones[count.index]
  map_public_ip_on_launch = true
  count                   = length(local.availability_zones)

  tags = {
    Name = "prod-public-subnet-${local.availability_zones[count.index]}"
  }
}

# Route Table을 생성합니다.
resource "aws_route_table" "public" {
  depends_on = [aws_internet_gateway.igw]
  vpc_id     = aws_vpc.prod.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "prod-public-route-table"
  }
}

# Route Table과 Subnet을 연결합니다.
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
  count          = length(aws_subnet.public)
}

# EIP를 생성합니다.
resource "aws_eip" "nat" {
  domain = "vpc"
  count  = length(local.availability_zones)

  lifecycle {
    create_before_destroy = true
  }
}

# Nat Gateway를 생성합니다.
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  count         = length(local.availability_zones)

  tags = {
    Name = "prod-nat-gateway-${local.availability_zones[count.index]}"
  }
}

# Private Subnet을 생성합니다.
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.prod.id
  cidr_block        = local.private_cidrs[count.index]
  availability_zone = element(local.availability_zones, floor(count.index / 2))
  count             = length(local.private_cidrs)

  tags = {
    Name = "prod-private-subnet-${element(local.availability_zones, floor(count.index / 2))}-${count.index}"
  }
}

# Private Route Table을 생성합니다.
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.prod.id
  count  = length(local.availability_zones)

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }

  tags = {
    Name = "prod-private-route-table-${local.availability_zones[count.index]}"
  }
}

# Route Table과 Subnet을 연결합니다.
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[floor(count.index / 2)].id
  count          = length(aws_subnet.private)
}