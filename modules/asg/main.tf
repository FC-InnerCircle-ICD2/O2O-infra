resource "aws_launch_template" "ProdLaunchTemplate" {
  name_prefix            = "ProdAutoScalingGroup"
  image_id               = var.ami.id
  instance_type          = "t3.large"
  key_name               = var.key_pair.key_name
  vpc_security_group_ids = [var.vpc_security_group.id]

  user_data = base64encode(templatefile("${path.module}/script.sh", {
    aws_access_key_id     = var.aws_access_key_id
    aws_secret_access_key = var.aws_secret_access_key
    aws_default_region    = var.aws_default_region
    s3_backend_bucket     = var.s3_backend_bucket
    s3_frontend_bucket    = var.s3_frontend_bucket
  }))

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "ProdAutoScalingGroup" {
  depends_on          = [aws_launch_template.ProdLaunchTemplate]
  name                = "ProdAutoScalingGroup"
  desired_capacity    = 2
  max_size            = 4
  min_size            = 2
  vpc_zone_identifier = [var.private_subnet_ids[0], var.private_subnet_ids[2]]

  launch_template {
    id      = aws_launch_template.ProdLaunchTemplate.id
    version = aws_launch_template.ProdLaunchTemplate.latest_version
  }

  tag {
    key                 = "Name"
    value               = "ProdAutoScalingGroup"
    propagate_at_launch = true
  }

  lifecycle {
    ignore_changes = [load_balancers, target_group_arns]
  }
}

resource "aws_autoscaling_attachment" "ProdAutoScalingALBattachment" {
  autoscaling_group_name = aws_autoscaling_group.ProdAutoScalingGroup.id
  lb_target_group_arn    = var.alb_target_group.arn
}
