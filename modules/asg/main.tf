resource "aws_launch_template" "ProdClientLaunchTemplate" {
  name_prefix            = "ProdClientAutoScalingGroup"
  image_id               = var.ami.id
  instance_type          = "t3.large"
  key_name               = var.key_pair.key_name
  vpc_security_group_ids = [var.vpc_security_group.id]

  iam_instance_profile {
    name = var.ec2_instance_profile.name
  }

  user_data = base64encode(templatefile("${path.module}/client_script.sh", {
    aws_access_key_id     = var.aws_access_key_id
    aws_secret_access_key = var.aws_secret_access_key
    aws_default_region    = var.aws_default_region
    s3_backend_bucket     = var.s3_backend_bucket
    s3_frontend_bucket    = var.s3_frontend_bucket
    grafana_root_url      = var.grafana_root_url
  }))

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "ProdClientAutoScalingGroup" {
  depends_on          = [aws_launch_template.ProdClientLaunchTemplate]
  name                = "ProdClientAutoScalingGroup"
  desired_capacity    = 1
  max_size            = 2
  min_size            = 1
  vpc_zone_identifier = [var.private_subnet_ids[0], var.private_subnet_ids[2]]

  launch_template {
    id      = aws_launch_template.ProdClientLaunchTemplate.id
    version = aws_launch_template.ProdClientLaunchTemplate.latest_version
  }

  tag {
    key                 = "Name"
    value               = "ProdClientAutoScalingGroup"
    propagate_at_launch = true
  }

  lifecycle {
    ignore_changes = [load_balancers, target_group_arns]
  }
}

resource "aws_autoscaling_attachment" "ProdClientAutoScalingALBattachment" {
  autoscaling_group_name = aws_autoscaling_group.ProdClientAutoScalingGroup.id
  lb_target_group_arn    = var.alb_target_group[0].arn
}

####################################################################################################################

resource "aws_launch_template" "ProdAdminLaunchTemplate" {
  name_prefix            = "ProdAdminAutoScalingGroup"
  image_id               = var.ami.id
  instance_type          = "t3.large"
  key_name               = var.key_pair.key_name
  vpc_security_group_ids = [var.vpc_security_group.id]

  iam_instance_profile {
    name = var.ec2_instance_profile.name
  }

  user_data = base64encode(templatefile("${path.module}/admin_script.sh", {
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

resource "aws_autoscaling_group" "ProdAdminAutoScalingGroup" {
  depends_on          = [aws_launch_template.ProdAdminLaunchTemplate]
  name                = "ProdAdminAutoScalingGroup"
  desired_capacity    = 1
  max_size            = 2
  min_size            = 1
  vpc_zone_identifier = [var.private_subnet_ids[0], var.private_subnet_ids[2]]

  launch_template {
    id      = aws_launch_template.ProdAdminLaunchTemplate.id
    version = aws_launch_template.ProdAdminLaunchTemplate.latest_version
  }

  tag {
    key                 = "Name"
    value               = "ProdAdminAutoScalingGroup"
    propagate_at_launch = true
  }

  lifecycle {
    ignore_changes = [load_balancers, target_group_arns]
  }
}

resource "aws_autoscaling_attachment" "ProdAdminAutoScalingALBattachment" {
  autoscaling_group_name = aws_autoscaling_group.ProdAdminAutoScalingGroup.id
  lb_target_group_arn    = var.alb_target_group[1].arn
}