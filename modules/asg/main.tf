resource "aws_launch_template" "MyLaunchTemplate" {
  name_prefix = "MyAutoScalingGroup"
  image_id = var.aws_ami.id
  instance_type = "t3.micro"
  key_name = var.aws_key_pair.key_name
  vpc_security_group_ids = [var.vpc_security_group.id]

  user_data = filebase64("${path.module}/script.sh")

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "MyAutoScalingGroup" {
  depends_on = [aws_launch_template.MyLaunchTemplate]
  name = "MyAutoScalingGroup"
  desired_capacity   = 2
  max_size           = 4
  min_size           = 2
  vpc_zone_identifier = [var.vpc_private_1_subnet.id, var.vpc_private_2_subnet.id]

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
  lb_target_group_arn    = var.aws_lb_target_group.arn
}
