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

# Obtener el ID de la subred privada para DRS
output "drs_subnet_id" {
  value       = aws_subnet.private_subnet_1.id
  description = "ID de la subred para el Staging Area de DRS"
}

# Obtener el ID del Security Group de DRS
output "drs_sg_id" {
  value       = aws_security_group.drs_sg.id
  description = "ID del Security Group para los servidores de DRS"
}