# 1. Crear el usuario IAM
resource "aws_iam_user" "cw_agent_user" {
  name = "cloudwatch-agente-gns3"
}

# 2. Crear las Access Keys para este usuario
resource "aws_iam_access_key" "cw_agent_keys" {
  user = aws_iam_user.cw_agent_user.name
}

# 3. Adjuntar la política estándar de AWS para agentes de CloudWatch
resource "aws_iam_user_policy_attachment" "cw_agent_policy" {
  user       = aws_iam_user.cw_agent_user.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# 4. (Opcional) Exportar las llaves a un archivo para que Ansible las lea o verlas en el output
output "cw_access_key" {
  value     = aws_iam_access_key.cw_agent_keys.id
  sensitive = true
}

output "cw_secret_key" {
  value     = aws_iam_access_key.cw_agent_keys.secret
  sensitive = true
}

# usuario para DRS

resource "aws_iam_user" "drs_agent_user" {
  name = "drs-agente-gns3"
}

resource "aws_iam_access_key" "drs_agent_keys" {
  user = aws_iam_user.drs_agent_user.name
}

# Política oficial de AWS para instalar el agente de DRS
resource "aws_iam_user_policy_attachment" "drs_agent_policy" {
  user       = aws_iam_user.drs_agent_user.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticDisasterRecoveryAgentInstallationPolicy"
}

# Exportar las llaves de DRS para Ansible
output "drs_access_key" {
  value     = aws_iam_access_key.drs_agent_keys.id
  sensitive = true
}

output "drs_secret_key" {
  value     = aws_iam_access_key.drs_agent_keys.secret
  sensitive = true
}