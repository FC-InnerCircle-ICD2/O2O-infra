resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "high-cpu-usage"                # CloudWatch 콘솔에서 알람을 식별
  comparison_operator = "GreaterThanOrEqualToThreshold" # 지표 값을 임계값과 비교하는 연산자 (GreaterThanThreshold, LessThanThreshold, LessThanOrEqualToThreshold, ...)
  evaluation_periods  = 2                               # 2회 연속으로 조건을 만족해야 알람이 트리거됨
  metric_name         = "CPUUtilization"                # 모니터링할 지표의 이름을 지정 (CPUUtilization (EC2 인스턴스의 CPU 사용률))
  namespace           = "AWS/EC2"                       # 지표가 속한 네임스페이스를 지정 (AWS/EC2 (EC2 관련 지표))
  period              = 60                              # 지표 데이터를 수집할 주기를 초 단위로 지정
  statistic           = "Average"                       # 지표 데이터에 적용할 통계 유형을 지정 (Sum, Minimum, Maximum, SampleCount, ...)
  threshold           = 70                              # 알람을 트리거할 임계값을 지정 (70 (CPU 사용률이 70% 이상일 때 알람 트리거))
  alarm_actions       = [var.aws_autoscaling_policy_scale_up.arn]

  dimensions = {
    AutoScalingGroupName = var.aws_autoscaling_group_client.name
  }
}

resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "low-cpu-usage"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 30
  alarm_actions       = [var.aws_autoscaling_policy_scale_down.arn]

  dimensions = {
    AutoScalingGroupName = var.aws_autoscaling_group_client.name
  }
}