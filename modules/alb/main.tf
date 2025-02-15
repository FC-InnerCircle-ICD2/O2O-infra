resource "aws_lb_target_group" "alb_target_group" {
  name        = "ProdAlbTargetGroup"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_resource.id
}

resource "aws_lb" "alb" {
  depends_on         = [aws_lb_target_group.alb_target_group]
  name               = "prod-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.vpc_security_group.id]
  subnets            = var.public_subnet_ids

  tags = {
    Name = "prod-alb"
  }
}

resource "aws_lb_listener" "abl_listener" {
  depends_on        = [aws_lb_target_group.alb_target_group]
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group.arn
  }
}