
# Crear la zona para tu dominio (ejemplo: tu-dominio.com)
resource "aws_route53_zone" "main" {
  name = "proyectos.bar" 

  tags = {
    Name = "zona-principal-integradora"
  }
}

# Crear el registro tipo 'A' (Alias) que apunta al ALB
resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.proyectos.bar" 
  type    = "A"

  alias {
    name                   = aws_lb.main_alb.dns_name
    zone_id                = aws_lb.main_alb.zone_id
    evaluate_target_health = true
  }
}

# Generar un archivo de texto con los Name Servers para tu referencia
resource "local_file" "godaddy_ns" {
  content  = <<-EOT
    Tus Name Servers para GoDaddy son:
    ${join("\n", aws_route53_zone.main.name_servers)}
  EOT
  filename = "${path.module}/nameservers_godaddy.txt"
}

# También los verás en la consola al terminar el apply
output "route53_nameservers" {
  value = aws_route53_zone.main.name_servers
}

# Registro Wildcard (*) que manda todos los subdominios al ALB
resource "aws_route53_record" "wildcard" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "*.proyectos.bar" 
  type    = "A"

  alias {
    name                   = aws_lb.main_alb.dns_name
    zone_id                = aws_lb.main_alb.zone_id
    evaluate_target_health = true
  }
}