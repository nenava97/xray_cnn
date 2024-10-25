#!/bin/bash

sudo apt-get update -y
sudo apt-get install -y redis-server
sudo apt install -y python3-pip python3-venv

# Download repo
git clone https://github.com/nenava97/xray_cnn.git /home/ubuntu/CNN_deploy

# Set permissions on the repo
sudo chown -R ubuntu:ubuntu /home/ubuntu/CNN_deploy

cd /home/ubuntu/CNN_deploy/pneumonia_api

# Set up virtual environment
python3 -m venv venv
source venv/bin/activate

# Install required packages
pip install --upgrade pip
pip install -r requirements.txt

# Ensure log files exist, set ownership to ubuntu, and permissions to be writable
sudo chown ubuntu:ubuntu /home/ubuntu/CNN_deploy/pneumonia_web/access.log /home/ubuntu/CNN_deploy/pneumonia_api/error.log
chmod 664 /home/ubuntu/CNN_deploy/pneumonia_web/access.log /home/ubuntu/CNN_deploy/pneumonia_api/error.log

# allow access from the ML training server
# vim /etc/redis/redis.conf
# bind 0.0.0.0 
# protected-mode no
# sudo systemctl restart redis

# Update the Redis configuration to allow access from any IP
sudo sed -i 's/^# bind 127.0.0.1 ::1/bind 0.0.0.0/' /etc/redis/redis.conf
sudo sed -i 's/^protected-mode yes/protected-mode no/' /etc/redis/redis.conf

# Restart Redis to apply the changes
sudo systemctl restart redis


#start gunicorn
gunicorn --config gunicorn_config.py app:app
