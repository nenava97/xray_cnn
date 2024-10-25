#!/bin/bash

sudo apt-get update
sudo apt-get install redis-server
sudo apt install python3-pip python3-venv

# download repo
git clone https://github.com/elmorenox/CNN_deploy.git

cd /CNN_deploy/pneumonia_api
python3 -m venv venv

source venv/bin/active

pip install --upgrade pip
pip install -r requirements.txt

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
