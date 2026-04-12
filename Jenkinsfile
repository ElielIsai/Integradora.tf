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

        stage('Terraform: Fase 1 (Solo DNS)') {
            steps {
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh 'terraform init'
                    echo "Creando SOLO la zona DNS para obtener los NameServers..."
                    // Al apuntar al local_file, Terraform crea la zona Route53 automáticamente por dependencia
                    sh 'terraform apply -target=local_file.godaddy_ns -target=aws_route53_zone.main -auto-approve'
                }
            }
        }

        stage('Actualizar DNS en GoDaddy (Python)') {
            steps {
                withCredentials([
                    string(credentialsId: 'GODADDY_KEY_ID', variable: 'TF_VAR_godaddy_key'),
                    string(credentialsId: 'GODADDY_SECRET_ID', variable: 'TF_VAR_godaddy_secret')
                ]) {
                    sh 'pip install requests'
                    echo "Enviando NameServers a GoDaddy..."
                    sh 'python3 actualizacion_dns.py'
                    // Le damos 30 segunditos a GoDaddy para que procese el cambio
                    sleep 30 
                }
            }
        }

        stage('Terraform: Fase 2 (Resto de la Infraestructura)') {
            steps {
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    echo "Desplegando EC2, VPN, ALB y validando ACM..."
                    // Ahora corre completo. Como GoDaddy ya está actualizado, ACM validará rapidísimo.
                    sh 'terraform apply -auto-approve'
                    
                    // Extraemos las llaves para Ansible
                    script {
                        env.CW_KEY = sh(script: 'terraform output -raw cw_access_key', returnStdout: true).trim()
                        env.CW_SECRET = sh(script: 'terraform output -raw cw_secret_key', returnStdout: true).trim()
                        env.DRS_KEY = sh(script: 'terraform output -raw drs_access_key', returnStdout: true).trim()
                        env.DRS_SECRET = sh(script: 'terraform output -raw drs_secret_key', returnStdout: true).trim()

                    }
                }
            }
        }

        stage('Configurar Nodos con Ansible') {
            steps {
                // Sacamos las contraseñas locales de la bóveda
                withCredentials([
                    string(credentialsId: 'ROUTER_PASS', variable: 'ROUTER_PASS'),
                    string(credentialsId: 'DEBIAN_PASS', variable: 'DEBIAN_PASS'),
                    string(credentialsId: 'DEBIANBD_PASS', variable: 'DEBIANBD_PASS')
                ]) {
                    sh 'chmod 400 llave-integradora.pem'
                    
                    // Ejecutamos Playbook de VPN (Routers)
                    sh """
                    ansible-playbook -i hosts.ini deploy_vpn.yml \
                    -e 'pass_router=${ROUTER_PASS}'
                    """

                    // Ejecutamos Playbook de CloudWatch (Debian)
                    sh """
                    ansible-playbook -i hosts.ini cloudwatch_gns3.yml \
                    -e 'aws_access_key_env=${env.CW_KEY}' \
                    -e 'aws_secret_key_env=${env.CW_SECRET}' \
                    -e 'pass_debian=${DEBIAN_PASS}'
                    """

                    sh """
                    ansible-playbook -i hosts.ini agente_DRS.yml \
                    -e 'aws_access_key_drs_env=${env.DRS_KEY}' \
                    -e 'aws_secret_key_drs_env=${env.DRS_SECRET}' \
                    -e 'pass_debianBD=${DEBIANBD_PASS}'
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