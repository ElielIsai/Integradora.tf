
# Alarma que monitorea el CPU (puedes enviarla desde GNS3 con el agente)
resource "aws_cloudwatch_metric_alarm" "cpu_usado" {
  alarm_name          = "cpu-gns3-server"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "cpu_usage_active"
  namespace           = "GNS3/Web" 
  period              = "60"
  statistic           = "Average"
  threshold           = "2"

  alarm_description = "Esta alarma dispara el escalado en AWS si el server local sufre"
  alarm_actions     = [aws_autoscaling_policy.scale_up_policy.arn]

  dimensions = {
    host = "debian"
    cpu  = "cpu-total"
  }
}

# Política de escalado para el ASG
resource "aws_autoscaling_policy" "scale_up_policy" {
  name                   = "scale-up-policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
}

# Alarma que monitorea si el servidor web local se cae
resource "aws_cloudwatch_metric_alarm" "web_server_caido" {
  alarm_name          = "caida-servidor-local-gns3"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1" # Si falla 1 minuto, dispara rápido
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "1" # Si 1 host (el local) está caído

  alarm_description = "Dispara el ASG si el servidor web de GNS3 deja de responder"
  alarm_actions     = [aws_autoscaling_policy.scale_up_policy.arn]

  # Le decimos que vigile específicamente el Target Group de tu servidor local
  dimensions = {
    TargetGroup  = aws_lb_target_group.web_tg.arn_suffix
    LoadBalancer = aws_lb.main_alb.arn_suffix
  }
}