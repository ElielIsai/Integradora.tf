# VPC Principal
resource "aws_vpc" "main_vpc" {
  cidr_block           = "20.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "vpc-integradora" }
}

# ZONA DE DISPONIBILIDAD A

# Subred Pública 1 Para el ALB
resource "aws_subnet" "public_subnet_1" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "20.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = { Name = "subred-publica-1" }
}

# Subred Privada 1 para tus EC2
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "20.0.10.0/24"
  availability_zone = "us-east-1a"
  tags = { Name = "subred-privada-web-1" }
}

# ZONA DE DISPONIBILIDAD B 

resource "aws_subnet" "public_subnet_2" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "20.0.2.0/24"
  availability_zone = "us-east-1b"
  tags = { Name = "subred-publica-2" }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "20.0.20.0/24"
  availability_zone = "us-east-1b"
  tags = { Name = "subred-privada-web-2" }
}

# Internet Gateway
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "igw-integradora"
  }
}
