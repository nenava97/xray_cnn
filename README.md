Kura Labs AI Workload 1
# Pneumonia Detection Application: MLOps Pipeline Setup and Optimization

## Overview

Welcome! You are an MLOps engineer working in a specialized team at Mount Sinai Hospital. Your team has developed a neural network application that allows doctors to upload x-ray images and receive a prediction on whether or not the x-ray indicates pneumonia. This application currently displays prediction results along with the percent accuracy for each diagnosis. The infrastructure, including backend, frontend, and monitoring, was manually configured to allow these components to interact seamlessly, and they are connected as shown in [this repo](https://github.com/elmorenox/CNN_deploy/blob/main/README.md). 

Initially, the application’s web server was accessible on a public subnet, where the UI was served on `public_ip:5001`. However, for enhanced security, there’s now a requirement to move the application to a private subnet and use Nginx on the public subnet to handle requests and serve the UI from `public_ip:80`. 

Additionally, concerns have been raised about model performance, as predictions show a tendency to classify everything as pneumonia. Your team is now tasked with automating this setup, sending accurate metrics to Prometheus and Grafana, and retraining the model to reduce bias in predictions and align with the updated system architecture shown below. 

![Screenshot 2024-10-26 130236](https://github.com/user-attachments/assets/33328621-4d3b-4234-aafa-2624e5f66ced)

Your role is to set up the automated CI/CD and MLOps pipelines, resolve infrastructure issues, and enhance model accuracy.

## Steps

1. **Set up Development Environment**
   - Spin up a `t3.medium` instance in your AWS account’s VPC.
   - Install **Jenkins** and **Terraform** (VSCode is optional but recommended).
   
2. **Clone and Prepare Repository**
   - Clone the project repository and upload it to your own GitHub account.
   - Update any file references to the repository URL to point to your new GitHub repository.
   
3. **Configure Jenkins**
   - Store your AWS access and secret keys securely in Jenkins for use in the multibranch pipeline.
   
4. **Run Initial Build**
   - Start a build of the pipeline. You will likely encounter errors due to issues in the Jenkinsfile or Terraform configuration files.
   - **Troubleshooting**: If errors arise, adjust the Jenkinsfile and/or files in the `terraform/` directory of your repository.
   
5. **Destroy Current Infrastructure**
   - Before each rebuild, ensure the current infrastructure is destroyed. Run `terraform destroy` in the repository’s Terraform directory on your Jenkins server (`/var/lib/jenkins/workspace/{project_name}/terraform`).

---

## Documentation

### Purpose
The purpose of this project is to automate the setup of the pneumonia detection application, enhance model accuracy, improve infrastructure security, and ensure the smooth flow of metrics to Prometheus and Grafana. The ultimate goal is to provide doctors with a reliable tool to support diagnosis decisions.

### Pipeline Overview
This system leverages Jenkins for CI/CD pipeline automation and Terraform for infrastructure management. The application is designed to allow x-ray images to be uploaded via the frontend, processed by a neural network model, and the results to be displayed on the UI. The pipeline handles both CI/CD and MLOps tasks, ensuring the model is continuously integrated, tested, and monitored for performance improvements.

#### Key Components:
   - **Frontend to Backend Communication**: Nginx acts as a reverse proxy on the public subnet, securing access to the UI while the application server remains on a private subnet.
   - **Metrics Collection**: Prometheus and Grafana gather metrics on model predictions and system performance, allowing for ongoing monitoring and optimization.

### Troubleshooting
As you proceed through the build process, you may encounter issues with infrastructure configuration and automated connections between frontend and backend components. Resolving these issues requires adjustments to the Jenkinsfile, Nginx settings, or Terraform files to ensure connectivity and proper resource allocation.

### Optimization
The model initially displayed a bias toward positive pneumonia predictions. To correct this:
   - Revisit the training process to adjust for class imbalance or overly sensitive thresholding.
   - Track relevant metrics such as prediction accuracy, false positives, and false negatives to monitor improvements over time.

   Further infrastructure improvements could include additional layers of security, auto-scaling for high availability, and more robust monitoring tools.

### Conclusion
Through this project, you gained experience in setting up automated CI/CD and MLOps pipelines, troubleshooting infrastructure for reliability, optimizing a neural network model, and enhancing infrastructure for security and performance. These skills are essential for scalable, production-ready machine learning solutions.

--- 

