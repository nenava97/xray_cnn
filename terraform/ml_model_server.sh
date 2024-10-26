#!/bin/bash

# Install wget if not already installed
sudo apt install wget -y

# Download and install Node Exporter
NODE_EXPORTER_VERSION="1.5.0"
wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
tar xvfz node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
sudo mv node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/
rm -rf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64*

# Create a Node Exporter user
sudo useradd --no-create-home --shell /bin/false node_exporter

# Create a Node Exporter service file
cat << EOF | sudo tee /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, start and enable Node Exporter service
sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl enable node_exporter

################################################################
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

cd /home/ubuntu/CNN_deploy/model

# Set up virtual environment
python3 -m venv venv
source venv/bin/activate

# Install required packages
pip install --upgrade pip
pip install -r requirements.txt

# # Run training
# echo "Starting model training..."
# python3 cnn.py

# # Run inference test
# # redis database must be set up on ml app server before this run so that db is available
# # Inference script must be configured with the private ip of the api server
# echo "Running inference tests..."
# python3 inference.py
