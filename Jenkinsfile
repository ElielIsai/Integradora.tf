pipeline {
    agent any

    environment {
        // Parametrizamos el dominio para tu script de Python
        DOMAIN = 'proyectos.bar'
        TF_IN_AUTOMATION = 'true'
        ANSIBLE_HOST_KEY_CHECKING = 'False' // Para evitar que Ansible se trabe preguntando (yes/no)
    }

    stages {
        stage('Obtener Código de GitHub') {
            steps {
                // Limpia el workspace de ejecuciones anteriores
                deleteDir()
                // Descarga tu repositorio de infraestructura
                git branch: 'main', 
                    credentialsId: 'ACCESO_REPO', 
                    url: 'https://github.com/ElielIsai/Integradora.tf.git'
            }
        }

        stage('Desplegar Infraestructura AWS (Terraform)') {
            steps {
                // Inyecta las credenciales temporales de AWS
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh 'terraform init'
                    
                    echo "Aplicando infraestructura en AWS..."
                    sh 'terraform apply -auto-approve'
                    
                    // EXTRAER LLAVES: Atrapamos las llaves del agente de CloudWatch que Terraform acaba de crear
                    script {
                        env.CW_KEY = sh(script: 'terraform output -raw cw_access_key', returnStdout: true).trim()
                        env.CW_SECRET = sh(script: 'terraform output -raw cw_secret_key', returnStdout: true).trim()
                    }
                }
            }
        }

        stage('Actualizar DNS en GoDaddy (Python)') {
            steps {
                // Inyecta las credenciales de GoDaddy
                withCredentials([
                    string(credentialsId: 'GODADDY_KEY_ID', variable: 'TF_VAR_godaddy_key'),
                    string(credentialsId: 'GODADDY_SECRET_ID', variable: 'TF_VAR_godaddy_secret')
                ]) {
                    // Asegura que la librería de Python esté instalada
                    sh 'pip install requests'
                    // Ejecuta el script que lee el nameservers_godaddy.txt
                    sh 'python3 actualizacion_dns.py'
                }
            }
        }

        stage('Configurar Nodos con Ansible') {
            steps {
                // Sacamos las contraseñas locales de la bóveda
                withCredentials([
                    string(credentialsId: 'ROUTER_PASS', variable: 'ROUTER_PASS'),
                    string(credentialsId: 'DEBIAN_PASS', variable: 'DEBIAN_PASS')
                ]) {
                    sh 'chmod 400 llave-integradora.pem'
                    
                    // Ejecutamos Playbook de CloudWatch (Debian)
                    sh """
                    ansible-playbook -i hosts.ini cloudwatch_gns3.yml \
                    -e "aws_access_key_env=${env.CW_KEY}" \
                    -e "aws_secret_key_env=${env.CW_SECRET}" \
                    -e "pass_debian=${DEBIAN_PASS}"
                    """
                    
                    // Ejecutamos Playbook de VPN (Routers)
                    sh """
                    ansible-playbook -i hosts.ini deploy_vpn.yml \
                    -e "pass_router=${ROUTER_PASS}"
                    """
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline completado. Revisa CloudWatch y GoDaddy para confirmar los cambios."
        }
        failure {
            echo "El pipeline falló. Revisa los logs arriba para identificar el error."
        }
    }
}