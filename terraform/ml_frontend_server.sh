#!/bin/bash

# Log all output for debugging
exec > /var/log/user_data.log 2>&1

# Automatically respond "yes" to prompts
sudo apt-get update -y

sudo apt install -y python3-pip python3-venv git

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

# # Ensure log files exist, set ownership to ubuntu, and permissions to be writable
# sudo chown ubuntu:ubuntu /home/ubuntu/CNN_deploy/pneumonia_web/access.log /home/ubuntu/CNN_deploy/pneumonia_web/error.log
# chmod 664 /home/ubuntu/CNN_deploy/pneumonia_web/access.log /home/ubuntu/CNN_deploy/pneumonia_web/error.log

# # Delay to ensure environment setup is complete
# sleep 10

# # Start the application with nohup to keep it running and log output
# nohup gunicorn --config gunicorn_config.py app:app &
