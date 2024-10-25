pipeline {
  agent any
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
                                    sh 'terraform apply -auto-approve tfplan'
                                    def outputs = sh(script: 'terraform output -json', returnStdout: true).trim()
                                    def parsedOutputs = readJSON text: outputs
                                    EC2_KEY = parsedOutputs.ec2_key.value
                                    API_SERVER_API = parsedOutputs.api_server_api.value
                                  } 
                                }
                            }
            }  
          }
      stage('Update Inference Script on ML Training Server') {
            steps {
                script {
                    // Replace 'backend' in inference.py with API_SERVER_API
                    sh """
                    ssh -i ${EC2_KEY} ubuntu@${ML_TRAINING_SERVER} "sed -i 's/backend/${API_SERVER_API}/g' CNN_deploy/model/inference.py"
                    """
                }
            }
        }
        stage('Update App Script on UI Server') {
            steps {
                script {
                    // Replace 'backend' in app.py with API_SERVER_API
                    sh """
                    ssh -i ${EC2_KEY} ubuntu@${UI_SERVER} "sed -i 's/backend/${API_SERVER_API}/g' CNN_deploy/pneumonia_web/app.py"
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
    }
}
// pipeline {
//     agent any

//     environment {
//         AWS_ACCESS_KEY_ID = credentials('aws-access-key-id') // Assumes AWS credentials are stored in Jenkins
//         AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
//         AWS_REGION = 'us-east-1'
//     }

//     stages {
//         stage('Checkout Code') {
//             steps {
//                 checkout scm
//             }
//         }

//         stage('Setup Environment') {
//             steps {
//                 script {
//                     echo 'Setting up Node.js and Python...'
//                 }
//                 // Install Node.js 20
//                 sh 'curl -sL https://deb.nodesource.com/setup_20.x | sudo -E bash -'
//                 sh 'sudo apt-get install -y nodejs'
                
//                 // Install Python 3.9
//                 sh 'sudo apt-get update && sudo apt-get install -y python3.9 python3.9-venv'
//                 sh 'python3.9 -m venv env && source env/bin/activate && pip install --upgrade pip'
//             }
//         }

//         stage('Build') {
//             steps {
//                 script {
//                     echo 'Running build steps...'
//                 }
//                 // Placeholder for actual build steps
//                 // e.g., running any necessary Node.js build steps or checks
//             }
//         }

//         stage('Test') {
//             steps {
//                 script {
//                     echo 'Running tests...'
//                 }
//                 // Placeholder for tests
//                 // e.g., sh 'npm test' or 'python -m unittest'
//             }
//         }

//         stage('Configure AWS Credentials') {
//             steps {
//                 withCredentials([
//                     string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
//                     string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
//                 ]) {
//                     sh 'aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID'
//                     sh 'aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY'
//                     sh 'aws configure set region $AWS_REGION'
//                 }
//             }
//         }

//         stage('Deploy Infrastructure with Terraform') {
//             steps {
//                 dir('terraform') {
//                     script {
//                         echo 'Initializing Terraform...'
//                     }
//                     sh 'terraform init'
                    
//                     script {
//                         echo 'Destroying existing Terraform infrastructure...'
//                     }
//                     sh 'terraform destroy -auto-approve'
                    
//                     script {
//                         echo 'Applying Terraform changes...'
//                     }
//                     sh 'terraform apply -auto-approve'
//                 }
//             }
//         }
//     }
    
//     post {
//         always {
//             echo 'Cleaning up...'
//             cleanWs()
//         }
//     }
// }
