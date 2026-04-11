# acm.tf

# Solicitar el certificado SSL
resource "aws_acm_certificate" "cert" {
  domain_name       = "*.proyectos.bar" # Protege el dominio y subdominios
  validation_method = "DNS"

  subject_alternative_names = ["proyectos.bar"]

  lifecycle {
    create_before_destroy = true
  }
}

# Crear el registro de validación en Route 53 automáticamente
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.main.zone_id
}

# Este recurso espera a que la validación se complete
resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}