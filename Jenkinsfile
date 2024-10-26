pipeline {
  agent any
  environment {
        EC2_KEY = ''
        APP_SERVER_API = ''
        NGINX_API = ''
        ML_TRAINING_SERVER_IP = ''
        MONITORING_SERVER = ''
        UI_SERVER_IP = ''
    }
    stages {
       stage('Init') {
         steps {
            dir('terraform') {
              sh 'terraform init' 
              }
          }
        }   
        stage('Plan') {
             steps {
              withCredentials([string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'aws_access_key_id'), 
                            string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'aws_secret_access_key')]) {
                                dir('terraform') {
                                  sh 'terraform plan -out plan.tfplan -var="aws_access_key_id=${aws_access_key_id}" -var="aws_secret_access_key=${aws_secret_access_key}"' 
                                }
              }
            }     
          }
        stage('Apply') {
            steps {
              withCredentials([string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'aws_access_key_id'), 
                            string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'aws_secret_access_key')]) {
                                dir('terraform') {
                                  script {
                                    sh 'terraform apply -auto-approve plan.tfplan'
                                    def outputs = sh(script: 'terraform output -json', returnStdout: true).trim()
                                    def parsedOutputs = readJSON text: outputs
                                    EC2_KEY = parsedOutputs.ec2_key.value
                                    APP_SERVER_API = parsedOutputs.app_server_api.value
                                  } 
                                }
                            }
            }  
          }
      stage('Update Inference Script on ML Training Server') {
            steps {
                script {
                    // Replace 'backend' in inference.py with APP_SERVER_API
                    sh """
                    ssh -i ${EC2_KEY} ubuntu@${ML_TRAINING_SERVER} "sed -i 's/backend/${APP_SERVER_API}/g' CNN_deploy/model/inference.py"
                    """
                }
            }
        }
        stage('Update App Script on UI Server') {
            steps {
                script {
                    // Replace 'backend' in app.py with APP_SERVER_API
                    sh """
                    ssh -i ${EC2_KEY} ubuntu@${UI_SERVER} "sed -i 's/backend/${APP_SERVER_API}/g' CNN_deploy/pneumonia_web/app.py"
                    """
                }
            }
        }
        stage('Application Setup on UI Server') {
            steps {
                script {
                    sh """
                    ssh -i ${EC2_KEY} ubuntu@${UI_SERVER} << EOF
                        cd ~/CNN_deploy/pneumonia_web
                        python3 -m venv venv
                        source venv/bin/activate
                        pip install -r requirements.txt
                        gunicorn --config gunicorn_config.py app:app
                    EOF
                    """
                }
            }
        }
    stage('Configure NginX on Nginx Server') {
            steps {
                script {
                    // Update NginX configuration file
                    sh """
                    ssh -i ${EC2_KEY} ubuntu@${NGINX_IP} "sudo sed -i '/location \\/ {/,+2d' /etc/nginx/sites-enabled/default && echo '\nlocation / {\\n    proxy_pass http://${UI_SERVER_IP}:5001;\\n    proxy_set_header Host \$host;\\n    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;\\n}' | sudo tee -a /etc/nginx/sites-enabled/default && sudo systemctl restart nginx"
                    """
                }
            }
        }
        stage('Configure Prometheus on Monitoring Server') {
            steps {
                script {
                    // Configure Prometheus to scrape ml_model_server
                    sh """
                    ssh -i ${EC2_KEY} ubuntu@${MONITORING_SERVER} << EOF
                        cat << PROM_CONFIG | sudo tee -a /opt/prometheus/prometheus.yml
                          - job_name: 'node_exporter'
                            static_configs:
                              - targets: ['${ML_TRAINING_SERVER_IP}:9100', '${ML_TRAINING_SERVER_IP}:8000']
                    PROM_CONFIG
                        sudo systemctl restart prometheus
                    EOF
                    """
                }
            }
        }
    }
}
