resource "aws_lb_target_group" "MyALBtargetgroup" {
  name     = "MyALBtargetgroup"
  target_type = "instance"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_resource.id
}

resource "aws_lb" "MyALB" {
  depends_on = [aws_lb_target_group.MyALBtargetgroup]
  name               = "MyALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.vpc_security_group.id]
  subnets            = [var.vpc_public_1_subnet.id, var.vpc_public_2_subnet.id]

  tags = {
    Name = "MyALB"
  }
}

resource "aws_lb_listener" "MyALBlistener" {
  depends_on = [aws_lb_target_group.MyALBtargetgroup]
  load_balancer_arn = aws_lb.MyALB.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.MyALBtargetgroup.arn
  }
}