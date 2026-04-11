# Obtener las IPs privadas de las instancias del ASG
data "aws_instances" "web_instances" {
  instance_tags = {
    "aws:autoscaling:groupName" = aws_autoscaling_group.web_asg.name
  }
}

output "instancias_privadas_ips" {
  value       = data.aws_instances.web_instances.private_ips
  description = "IPs privadas para el inventario de Ansible"
}