# 1. TABLA DE RUTEO PÚBLICA

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  # Regla: Todo el tráfico (0.0.0.0/0) va hacia el Internet Gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "tabla-ruteo-publica"
  }
}

# Asociar Subred Pública 1 a la Tabla Pública
resource "aws_route_table_association" "public_assoc_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

# Asociar Subred Pública 2 a la Tabla Pública
resource "aws_route_table_association" "public_assoc_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}


# 2. TABLA DE RUTEO PRIVADA

# Por ahora no le ponemos ruta a internet (0.0.0.0/0), 
# por lo que solo se comunicará internamente dentro de la VPC.
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "tabla-ruteo-privada"
  }

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
}

# Asociar Subred Privada 1 a la Tabla Privada
resource "aws_route_table_association" "private_assoc_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_rt.id
}

# Asociar Subred Privada 2 a la Tabla Privada
resource "aws_route_table_association" "private_assoc_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}