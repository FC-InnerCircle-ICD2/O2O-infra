# EC2가 사용할 private address를 생성합니다.
resource "aws_network_interface" "bastion" {
  subnet_id       = var.public_subnet_ids[count.index]
  private_ips     = [ "10.0.${count.index + 1}.100" ]
  security_groups = [ var.vpc_security_group.id ]
  count           = length(var.public_subnet_ids)

  tags = {
    Name = "prod-bastion-nic-${count.index + 1}"
  }
}

# EC2 인스턴스를 생성합니다.
resource "aws_instance" "bastion" {
  ami                     = var.ami.id
  instance_type           = "t2.micro"
  key_name                = var.key_pair.key_name
  count                   = length(var.public_subnet_ids)

  network_interface {
    network_interface_id  = aws_network_interface.bastion[count.index].id
    device_index          = 0
  }

  tags = {
    Name = "prod-bastion-${count.index + 1}"
  }
}