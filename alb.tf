resource "aws_lb_target_group" "MyALBtargetgroup" {
  depends_on = [aws_vpc.MyVPC08]
  name     = "MyALBtargetgroup"
  target_type = "instance"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.MyVPC08.id
}

resource "aws_lb" "MyALB" {
  depends_on = [aws_lb_target_group.MyALBtargetgroup]
  name               = "MyALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.MySecurityGroup.id]
  subnets            = [aws_subnet.MyPublic1Subnet.id, aws_subnet.MyPublic2Subnet.id]

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