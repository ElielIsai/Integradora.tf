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
                git branch: 'main', url: 'https://github.com/Eliellsai/Integradora.tf.git'
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
                // 1. Damos permisos correctos a la llave que Terraform acaba de crear para que SSH no se queje
                sh 'chmod 400 llave-integradora.pem'
                
                // 2. Ejecutamos el Playbook de CloudWatch pasándole las llaves dinámicas
                sh """
                ansible-playbook -i hosts.ini cloudwatch_gns3.yml \
                -e "aws_access_key_env=${env.CW_KEY}" \
                -e "aws_secret_key_env=${env.CW_SECRET}"
                """
                
                // 3.  Ejecutamos Playbook de la VPN
                sh 'ansible-playbook -i hosts.ini deploy_vpn.yml'
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