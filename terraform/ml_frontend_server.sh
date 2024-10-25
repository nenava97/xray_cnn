#!/bin/bash

# Automatically respond "yes" to prompts
sudo apt-get update -y

sudo apt install -y python3-pip python3-venv

# Download repo
git clone https://github.com/elmorenox/CNN_deploy.git

cd ~/CNN_deploy/pneumonia_web

# Set up virtual environment
python3 -m venv venv

source venv/bin/activate

# Install required packages
pip install --upgrade pip
pip install -r requirements.txt

# Start the application
gunicorn --config gunicorn_config.py app:app
