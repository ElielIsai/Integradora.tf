# Alarma CPU alto → escalar + distribuir carga 50/50
resource "aws_cloudwatch_metric_alarm" "cpu_usado" {
  alarm_name          = "cpu-gns3-server"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "cpu_usage_active"
  namespace           = "GNS3/Web"
  period              = "60"
  statistic           = "Average"
  threshold           = "60"
  alarm_description   = "CPU del servidor GNS3 supera 60%"

  alarm_actions = [
    aws_autoscaling_policy.scale_up_policy.arn,
    aws_sns_topic.failover_topic.arn
  ]

  dimensions = {
    host = "debian"
    cpu  = "cpu-total"
  }
}

# Política de escalado del ASG
resource "aws_autoscaling_policy" "scale_up_policy" {
  name                   = "scale-up-policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
}

# Alarma caída servidor → failover completo a EC2
resource "aws_cloudwatch_metric_alarm" "web_server_caido" {
  alarm_name          = "caida-servidor-local-gns3"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "1"
  alarm_description   = "El servidor GNS3 dejo de responder"

  alarm_actions = [
    aws_autoscaling_policy.scale_up_policy.arn,
    aws_sns_topic.failover_topic.arn
  ]

  dimensions = {
    TargetGroup  = aws_lb_target_group.web_tg.arn_suffix
    LoadBalancer = aws_lb.main_alb.arn_suffix
  }
}

resource "aws_sns_topic" "failover_topic" {
  name = "failover-gns3-a-ec2"
}

resource "aws_sns_topic_subscription" "lambda_sub" {
  topic_arn = aws_sns_topic.failover_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.cambiar_pesos.arn
}