
# CUSTOMER GATEWAY (mi router local)
resource "aws_customer_gateway" "cgw" {
  # El BGP ASN de la red local
  bgp_asn = 65000

  # mi ip publica
  ip_address = "187.191.33.41"
  type       = "ipsec.1"

  tags = {
    Name = "cgw-router-local"
  }
}

# VIRTUAL PRIVATE GATEWAY (El lado de AWS)
resource "aws_vpn_gateway" "vgw" {
  vpc_id = aws_vpc.main_vpc.id
  # AWS usa el ASN 64512 por defecto
  amazon_side_asn = 64512

  tags = {
    Name = "vgw-integradora"
  }
}

#  CONEXION VPN (El Túnel)
resource "aws_vpn_connection" "main_vpn" {
  vpn_gateway_id      = aws_vpn_gateway.vgw.id
  customer_gateway_id = aws_customer_gateway.cgw.id
  type                = "ipsec.1"

  # Habilitamos rutas dinámicas porque estamos usando BGP
  static_routes_only = false

  tags = {
    Name = "vpn-site-to-site"
  }
}

# PROPAGACION DE RUTAS para qeu aws aprenda las rutas que mi router local anuncia por BGP a través del túnel VPN.
resource "aws_vpn_gateway_route_propagation" "private_prop" {
  vpn_gateway_id = aws_vpn_gateway.vgw.id
  route_table_id = aws_route_table.private_rt.id
}


# INTEGRACIÓN CON ANSIBLE (Variables para que ansible configure el túnel VPN en el router local)

resource "local_file" "ansible_vpn_vars" {
  # Creamos un archivo de variables YAML para Ansible
  content = <<-EOT
---
# Archivo autogenerado por Terraform
aws_tunnel1_ip: "${aws_vpn_connection.main_vpn.tunnel1_address}"
aws_tunnel1_psk: "${aws_vpn_connection.main_vpn.tunnel1_preshared_key}"
aws_tunnel1_bgp_asn: "64512"
aws_tunnel1_bgp_ip: "${aws_vpn_connection.main_vpn.tunnel1_vgw_inside_address}"

aws_tunnel2_ip: "${aws_vpn_connection.main_vpn.tunnel2_address}"
aws_tunnel2_psk: "${aws_vpn_connection.main_vpn.tunnel2_preshared_key}"
aws_tunnel2_bgp_ip: "${aws_vpn_connection.main_vpn.tunnel2_vgw_inside_address}"

aws_tunnel1_cgw_ip: "${aws_vpn_connection.main_vpn.tunnel1_cgw_inside_address}"
aws_tunnel2_cgw_ip: "${aws_vpn_connection.main_vpn.tunnel2_cgw_inside_address}"
EOT

  # Lo guardamos en la carpeta donde se trabaja con Ansible
  filename = "${path.module}/vpn_vars.yml"
}

resource "aws_vpn_gateway_route_propagation" "public_prop" {
  vpn_gateway_id = aws_vpn_gateway.vgw.id
  route_table_id = aws_route_table.public_rt.id
}