#!/bin/bash

# Exit on any error
set -e

echo "Starting ML training server setup..."

# Update and install basic packages
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y \
    python3-pip \
    python3-venv \
    awscli \
    wget \
    git \
    build-essential
sudo apt-get install unzip  # Added unzip installation

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install NVIDIA drivers and CUDA
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt-get update
sudo apt-get -y install cuda-drivers
sudo apt-get install -y cuda

# Set up CUDA environment variables
echo 'export PATH=/usr/local/cuda/bin:$PATH' >> /.bashrc
echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH' >> /.bashrc
source /.bashrc


echo "GPU setup complete. Rebooting..."
sudo reboot

# Download dataset from S3
# aws cli must be set up before this step
aws s3 cp s3://x-raysbucket/chest_xray/ /home/ubuntu/chest_xray --recursive

# Download repo
git clone https://github.com/nenava97/xray_cnn.git /home/ubuntu/CNN_deploy

# Set permissions on the repo
sudo chown -R ubuntu:ubuntu /home/ubuntu/CNN_deploy

cd /home/ubuntu/CNN_deploy/pneumonia_web

# Set up virtual environment
python3 -m venv venv
source venv/bin/activate

# Install required packages
pip install --upgrade pip
pip install -r requirements.txt

# Run training
echo "Starting model training..."
python3 cnn.py

# Run inference test
# redis database must be set up on ml app server before this run so that db is available
# Inference script must be configured with the private ip of the api server
echo "Running inference tests..."
python3 inference.py
