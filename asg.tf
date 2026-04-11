data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_launch_template" "web_launch_template" {
  name_prefix   = "plantilla-web"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"

  key_name = aws_key_pair.deployer.key_name

  network_interfaces {
    associate_public_ip_address = false # Cambia a true si no usas NAT Gateway y necesitas internet
    security_groups             = [aws_security_group.web_sg.id]
  }

  # Script para levantar tu contenedor al iniciar
  user_data = base64encode(<<-EOF
              #!/bin/bash
              # Actualizar e instalar Docker y Git
              yum update -y
              yum install -y docker git
              systemctl start docker
              systemctl enable docker
              
              # Instalar Docker Compose (Amazon Linux 2023)
              curl -SL https://github.com/docker/compose/releases/download/v2.24.5/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
              chmod +x /usr/local/bin/docker-compose

              # Clonar tu repositorio con los archivos
              cd /home/ec2-user
              git clone https://github.com/ElielIsai/Integradora.git
              cd Integradora

              # Levantar los contenedores (NPM + Webs)
              docker-compose up -d
              EOF
  )
}

resource "aws_autoscaling_group" "web_asg" {
  desired_capacity    = 0
  max_size            = 2
  min_size            = 0
  target_group_arns   = [aws_lb_target_group.ec2_tg.arn] 
  vpc_zone_identifier = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id] 

  launch_template {
    id      = aws_launch_template.web_launch_template.id
    version = "$Latest"
  }
}

resource "tls_private_key" "nueva_llave" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "deployer" {
  key_name   = "llave-integradora"
  public_key = tls_private_key.nueva_llave.public_key_openssh
}

resource "local_file" "ssh_key" {
  filename        = "${path.module}/llave-integradora.pem"
  content         = tls_private_key.nueva_llave.private_key_pem
  file_permission = "0400"
}

# Agregamos NAT Gateway y Elastic IP para que las instancias en subredes privadas puedan acceder a internet
resource "aws_eip" "nat" { domain = "vpc" }

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_subnet_1.id
}
