resource "aws_lb" "main_alb" {
  name               = "alb-integradora"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id] # 
}

resource "aws_lb_target_group" "web_tg" { 
  name        = "web-tg-ip"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main_vpc.id # [cite: 1]
  target_type = "ip"


  health_check {
    path                = "/" # Ruta para el health check, puede ser cualquier endpoint que devuelva 200 OK
    protocol            = "HTTP"
    matcher             = "200-399" # Ampliamos el rango por si NPM hace redirecciones
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  lifecycle {
    create_before_destroy = true
  }
}
# Target group para EC2
resource "aws_lb_target_group" "ec2_tg" {
  name        = "ec2-tg-instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main_vpc.id
  target_type = "instance"       

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_target_group_attachment" "gns3_server" {
  target_group_arn  = aws_lb_target_group.web_tg.arn
  target_id         = "10.200.1.6" # IP privada del servidor GNS3
  port              = 80
  availability_zone = "all"
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.main_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate_validation.cert.certificate_arn

  # Default: siempre va a GNS3
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# regla que se activa SOLO cuando el ASG tiene instancias corriendo
resource "aws_lb_listener_rule" "ec2_overflow" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 1

  action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.web_tg.arn
        weight = 100   # cuando escala, distribuye carga
      }
      target_group {
        arn    = aws_lb_target_group.ec2_tg.arn
        weight = 0
      }
      stickiness {
        enabled  = true
        duration = 300
      }
    }
  }

  # Solo aplica esta regla cuando hay EC2 activas
  # Condición: siempre activa, pero tú controlas si existe o no el recurso
  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

