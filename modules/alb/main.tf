resource "aws_lb_target_group" "alb_target_group" {
  name        = "ProdAlbTargetGroup-${count.index}"
  target_type = "instance"
  port        = "80"
  protocol    = "HTTP"
  vpc_id      = var.vpc_resource.id
  count       = length(2)
}

resource "aws_lb" "alb" {
  depends_on         = [aws_lb_target_group.alb_target_group]
  name               = "prod-alb-${count.index}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.vpc_security_group.id]
  subnets            = var.public_subnet_ids
  count              = length(2)

  tags = {
    Name = "prod-alb-${count.index}"
  }
}

resource "aws_lb_listener" "abl_listener" {
  depends_on        = [aws_lb_target_group.alb_target_group]
  load_balancer_arn = aws_lb.alb[count.index].arn
  port              = "80"
  protocol          = "HTTP"
  count             = length(2)

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group[count.index].arn
  }
}