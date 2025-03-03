output "aws_autoscaling_group_client" {
  value = aws_autoscaling_group.ProdClientAutoScalingGroup
}

output "aws_autoscaling_policy_scale_up" {
  value = aws_autoscaling_policy.scale_up
}

output "aws_autoscaling_policy_scale_down" {
  value = aws_autoscaling_policy.scale_down
}