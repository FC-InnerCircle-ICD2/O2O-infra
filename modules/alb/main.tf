locals {
  ports = ["80", "8082"]
}

resource "aws_lb_target_group" "alb_target_group" {
  name        = "ProdAlbTargetGroup${local.ports[count.index]}"
  target_type = "instance"
  port        = "80"
  protocol    = "HTTP"
  vpc_id      = var.vpc_resource.id
  count       = length(local.ports)
}

resource "aws_lb" "alb" {
  depends_on         = [aws_lb_target_group.alb_target_group[0], aws_lb_target_group.alb_target_group[1]]
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
  depends_on        = [aws_lb_target_group.alb_target_group[0], aws_lb_target_group.alb_target_group[1]]
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
      host        = "#{host}"
      path        = "/#{path}"
      query       = "#{query}"
    }
  }
}

resource "aws_lb_listener" "https" {
  depends_on        = [aws_lb_target_group.alb_target_group[0], aws_lb_target_group.alb_target_group[1]]
  load_balancer_arn = aws_lb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.acm_certificate.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group[0].arn
  }
}

resource "aws_lb_listener_rule" "root" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 2

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group[0].arn
  }

  condition {
    host_header {
      values = ["gaebalmin.com"]
    }
  }
}

resource "aws_lb_listener_rule" "sub" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group[1].arn
  }

  condition {
    host_header {
      values = ["ceo.gaebalmin.com"]
    }
  }
}