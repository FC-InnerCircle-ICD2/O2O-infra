# 모니터링을 위한 EC2 인스턴스에 환경변수를 전달합니다.
data "template_file" "monitor_instance_user_data" {
  template = file("${path.module}/script.sh")

  vars = {
    aws_access_key_id          = var.aws_access_key_id
    aws_secret_access_key      = var.aws_secret_access_key
    aws_default_region         = var.aws_default_region
    s3_backend_bucket          = var.s3_backend_bucket
    gf_security_admin_user     = var.gf_security_admin_user
    gf_security_admin_password = var.gf_security_admin_password
    grafana_root_url           = var.grafana_root_url
  }
}

# 모니터링을 위한 EC2 인스턴스를 생성합니다.
resource "aws_instance" "monitor" {
  ami                    = var.ami.id
  instance_type          = "t3.large"
  key_name               = var.key_pair.key_name
  availability_zone      = var.availability_zones[1]
  subnet_id              = var.private_subnet_ids[3]
  vpc_security_group_ids = [var.vpc_security_group.id]
  private_ip             = "10.0.6.100"

  iam_instance_profile = var.ec2_instance_profile.name

  user_data = data.template_file.monitor_instance_user_data.rendered

  tags = {
    Name = "prod-monitor-instance"
  }
}

resource "aws_lb_target_group_attachment" "ProdMonitorALBattachment" {
  target_group_arn = var.alb_target_group[2].arn
  target_id        = aws_instance.monitor.id
  port             = 80
}
