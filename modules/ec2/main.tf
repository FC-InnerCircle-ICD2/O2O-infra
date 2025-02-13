# Bastion EC2가 사용할 private address를 생성합니다.
resource "aws_network_interface" "bastion" {
  subnet_id       = var.public_subnet_ids[count.index]
  private_ips     = ["10.0.${count.index + 1}.100"]
  security_groups = [var.vpc_security_group.id]
  count           = length(var.public_subnet_ids)

  tags = {
    Name = "prod-bastion-nic-${count.index + 1}"
  }
}

# Bastion EC2 인스턴스를 생성합니다.
resource "aws_instance" "bastion" {
  ami               = var.ami.id
  instance_type     = "t2.micro"
  key_name          = var.key_pair.key_name
  availability_zone = var.availability_zones[count.index]
  count             = length(var.public_subnet_ids)

  network_interface {
    network_interface_id = aws_network_interface.bastion[count.index].id
    device_index         = 0
  }

  tags = {
    Name = "prod-bastion-instance-${count.index + 1}"
  }
}

# Database를 모아둔 EC2 인스턴스에 환경변수를 전달합니다.
data "template_file" "db_instance_user_data" {
  template = file("${path.module}/script.sh")

  vars = {
    postgres_user         = var.postgres_user
    postgres_password     = var.postgres_password
    s3_flyway_bucket      = var.s3_flyway_bucket
    aws_access_key_id     = var.aws_access_key_id
    aws_secret_access_key = var.aws_secret_access_key
    aws_default_region    = var.aws_default_region
  }
}

# Database를 모아둔 EC2 인스턴스를 생성합니다.
resource "aws_instance" "db" {
  ami                    = var.ami.id
  instance_type          = "t2.micro"
  key_name               = var.key_pair.key_name
  availability_zone      = var.availability_zones[0]
  subnet_id              = var.private_subnet_ids[1]
  vpc_security_group_ids = [var.vpc_security_group.id]
  private_ip             = "10.0.4.100"

  user_data = data.template_file.db_instance_user_data.rendered

  tags = {
    Name = "prod-db-instance"
  }
}