# Le decimos a Terraform que adopte la plantilla que ya existe en AWS
import {
  to = aws_drs_replication_configuration_template.drs_template
  id = "rct-3287d390ed8db2740"
  
}

# 1. Grupo de Seguridad para los servidores de replicación de DRS
resource "aws_security_group" "drs_sg" {
  name        = "drs-replication-sg"
  description = "Security group para servidores de DRS"
  vpc_id      = aws_vpc.main_vpc.id 

  ingress {
    description = "Permitir trafico de replicacion DRS desde Debian"
    from_port   = 1500
    to_port     = 1500
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"] 
  }

  # Regla de salida: Permite al servidor de DRS comunicarse con internet/AWS
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "drs-sg"
  }
}

# 2. Inicialización de la plantilla de Elastic Disaster Recovery (DRS)
resource "aws_drs_replication_configuration_template" "drs_template" {
  
  staging_area_subnet_id = aws_subnet.private_subnet_1.id

  # Configuraciones estándar
  associate_default_security_group = true
  bandwidth_throttling             = 0
  create_public_ip                 = false
  data_plane_routing               = "PRIVATE_IP"
  default_large_staging_disk_type  = "AUTO"
  ebs_encryption                   = "DEFAULT"
  replication_server_instance_type = "t3.small"
  use_dedicated_replication_server        = false 
  replication_servers_security_groups_ids = [aws_security_group.drs_sg.id]

 



  staging_area_tags = {
    Name = "DRS-Replication-Server"
  }
  # Regla 1: Retener un snapshot cada 10 minutos durante la última hora
  pit_policy {
    rule_id            = 1
    units              = "MINUTE"
    interval           = 10
    retention_duration = 60 
    enabled            = true
  }

  # Regla 2: Retener un snapshot cada hora durante las últimas 24 horas
  pit_policy {
    rule_id            = 2
    units              = "HOUR"
    interval           = 1
    retention_duration = 24 
    enabled            = true
  }

  # Regla 3: Retener un snapshot diario durante los últimos 7 días
  pit_policy {
    rule_id            = 3
    units              = "DAY"
    interval           = 1
    retention_duration = 7 
    enabled            = true
  }
}