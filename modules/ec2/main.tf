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
  ami           = var.ami.id
  instance_type = "t2.micro"
  key_name      = var.key_pair.key_name
  count         = length(var.public_subnet_ids)

  network_interface {
    network_interface_id = aws_network_interface.bastion[count.index].id
    device_index         = 0
  }

  tags = {
    Name = "prod-bastion-${count.index + 1}"
  }
}

# Database EC2 인스턴스를 생성합니다.
resource "aws_instance" "database_app_instance" {
  ami                         = var.ami.id
  instance_type               = "t2.micro"
  key_name                    = var.key_pair.key_name
  subnet_id                   = var.private_subnet_ids[2]
  vpc_security_group_ids      = [var.vpc_security_group.id]
  private_ip                  = "10.0.5.100"
  associate_public_ip_address = false

  user_data = filebase64("${path.module}/script.sh")

  tags = {
    Name = "prod-database-app"
  }
}