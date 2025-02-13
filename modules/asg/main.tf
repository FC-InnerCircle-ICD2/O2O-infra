data "template_file" "app_instance_user_data" {
  template = file("${path.module}/script.sh")

  vars = {
    frontend_shop_bucket  = var.s3_frontend_shop_bucket
    aws_access_key_id     = var.aws_access_key_id
    aws_secret_access_key = var.aws_secret_access_key
    aws_default_region    = var.aws_default_region
    s3_frontend_shop_bucket = var.s3_frontend_shop_bucket
  }
}

resource "aws_launch_template" "MyLaunchTemplate" {
  name_prefix            = "MyAutoScalingGroup"
  image_id               = var.ami.id
  instance_type          = "t2.micro"
  key_name               = var.key_pair.key_name
  vpc_security_group_ids = [var.vpc_security_group.id]

  user_data = data.template_file.app_instance_user_data.rendered

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "MyAutoScalingGroup" {
  depends_on          = [aws_launch_template.MyLaunchTemplate]
  name                = "MyAutoScalingGroup"
  desired_capacity    = 2
  max_size            = 4
  min_size            = 2
  vpc_zone_identifier = [var.private_subnet_ids[0], var.private_subnet_ids[2]]

  launch_template {
    id      = aws_launch_template.MyLaunchTemplate.id
    version = aws_launch_template.MyLaunchTemplate.latest_version
  }

  tag {
    key                 = "Name"
    value               = "MyAutoScalingGroup"
    propagate_at_launch = true
  }

  lifecycle {
    ignore_changes = [load_balancers, target_group_arns]
  }
}

resource "aws_autoscaling_attachment" "MyAutoScalingALBattachment" {
  autoscaling_group_name = aws_autoscaling_group.MyAutoScalingGroup.id
  lb_target_group_arn    = var.alb_target_group.arn
}
