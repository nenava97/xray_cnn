provider "aws" {
  region = "us-east-1"
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
}

# VPC
resource "aws_vpc" "ml_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "ml_vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "ml_internet_gateway" {
  vpc_id = aws_vpc.ml_vpc.id
  tags = {
    Name = "ml_internet_gateway"
  }
}

# Subnets
resource "aws_subnet" "ml_public_subnet" {
  vpc_id            = aws_vpc.ml_vpc.id
  cidr_block        = var.subnet_cidr_blocks[0]
  availability_zone = var.app_availability_zone

  tags = {
    Name = "ml_public_subnet"
  }
}

resource "aws_subnet" "ml_private_subnet_app" {
  vpc_id            = aws_vpc.ml_vpc.id
  cidr_block        = var.subnet_cidr_blocks[1]
  availability_zone = var.app_availability_zone

  tags = {
    Name = "ml_private_subnet_app"
  }
}

resource "aws_subnet" "ml_private_subnet_training" {
  vpc_id            = aws_vpc.ml_vpc.id
  cidr_block        = var.subnet_cidr_blocks[2]
  availability_zone = var.ml_availability_zone

  tags = {
    Name = "ml_private_subnet_training"
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = {
    Name = "ml_nat_gateway_eip"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "ml_nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.ml_public_subnet.id

  tags = {
    Name = "ml_nat_gateway"
  }

  depends_on = [aws_internet_gateway.ml_internet_gateway]
}

# Route Tables
resource "aws_route_table" "ml_public" {
  vpc_id = aws_vpc.ml_vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ml_internet_gateway.id
  }

  tags = { Name = "ml_public" }
}

resource "aws_route_table" "ml_private" {
  vpc_id = aws_vpc.ml_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ml_nat_gateway.id
  }

  tags = { Name = "ml_private" }
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.ml_public_subnet.id
  route_table_id = aws_route_table.ml_public.id
}

resource "aws_route_table_association" "private_app" {
  subnet_id      = aws_subnet.ml_private_subnet_app.id
  route_table_id = aws_route_table.ml_private.id
}

resource "aws_route_table_association" "private_training" {
  subnet_id      = aws_subnet.ml_private_subnet_training.id
  route_table_id = aws_route_table.ml_private.id
}

# Security Groups
resource "aws_security_group" "ml_frontend_security_group" {
  name_prefix = "ml_frontend_"
  vpc_id      = aws_vpc.ml_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS access"
  }

  ingress {
    from_port   = 5001
    to_port     = 5001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
    description = "Gunicorn port for Flask UI"
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
    description = "Grafana"
  }

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
    description = "Prometheus"
  }

  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
    description = "Node Exporter"
  }

  # Allow communication between frontend servers
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    self            = true
    description     = "Allow all traffic between frontend servers"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ml_frontend_security_group"
  }
}

resource "aws_security_group" "ml_backend_security_group" {
  vpc_id = aws_vpc.ml_vpc.id
  name   = "ML Backend Security"

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "TCP"
    #cidr_blocks = ["0.0.0.0/0"] 
    self      = true  # This allows instances in this security group to communicate
    security_groups = [aws_security_group.ml_frontend_security_group.id]
    description     = "SSH access"
  }

  ingress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.ml_frontend_security_group.id]
    description     = "API access from frontend"
  }
  
  ingress {
    from_port   = 5001
    to_port     = 5001
    protocol    = "tcp"
    security_groups = [aws_security_group.ml_frontend_security_group.id]
    description = "Gunicorn port for Flask UI"
  }
  
  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.ml_frontend_security_group.id]
    description     = "model metrics"
  }

  ingress {
    from_port       = 9100
    to_port         = 9100
    protocol        = "tcp"
    security_groups = [aws_security_group.ml_frontend_security_group.id]
    description     = "node exporter"
  }
  
  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description     = "Redis access from training server"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ml_backend_security_group"
  }
}

# EC2 Instances
resource "aws_instance" "ml_nginx_server" {
  ami                         = var.ec2_ami
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.ml_public_subnet.id
  vpc_security_group_ids      = [aws_security_group.ml_frontend_security_group.id]
  key_name                    = aws_key_pair.my_key.key_name
  associate_public_ip_address = true
  user_data = <<-EOF
    #!/bin/bash
    sudo apt-get update -y
    sudo apt-get install -y python3-pip
    sudo apt-get install -y nginx
  EOF

  tags = {
    Name = "ml_nginx_server"
  }
}

resource "aws_instance" "monitoring_server" {
  ami                         = var.ec2_ami
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.ml_public_subnet.id
  vpc_security_group_ids      = [aws_security_group.ml_frontend_security_group.id]
  key_name                    = aws_key_pair.my_key.key_name
  associate_public_ip_address = true
  user_data = "${file("monitoring_server.sh")}"
  tags = {
    Name = "ml_monitor_server"
  }
}

resource "aws_instance" "ml_ui_server" {
  ami                         = var.ec2_ami
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.ml_private_subnet_app.id
  vpc_security_group_ids      = [aws_security_group.ml_backend_security_group.id]
  key_name                    = aws_key_pair.my_key.key_name
  user_data = "${file("ml_frontend_server.sh")}"
  tags = {
    Name = "ml_ui_server"
  }
}

resource "aws_instance" "ml_app_server" {
  ami                    = var.ec2_ami
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.ml_private_subnet_app.id
  vpc_security_group_ids = [aws_security_group.ml_backend_security_group.id]
  key_name               = aws_key_pair.my_key.key_name
  user_data              = file("ml_app_server.sh")

  # Wait for user_data to complete by checking NginX or Redis installation
#  provisioner "remote-exec" {
#    inline = [
#      # Check for the Redis directory, create if it doesn't exist
#      "if [ ! -d /etc/redis ]; then sudo mkdir -p /etc/redis; fi",
#      # Wait until Redis is installed by checking for redis-server binary
#      "while ! command -v redis-server >/dev/null 2>&1; do sleep 5; done"
#    ]
#    connection {
#      type           = "ssh"
#      user           = "ubuntu"
#      private_key    = tls_private_key.my_key.private_key_pem
#      host           = self.private_ip  # Use private IP since it's in a private subnet
#      bastion_host   = aws_instance.ml_nginx_server.public_ip
#      bastion_user   = "ubuntu"
#      bastion_private_key = tls_private_key.my_key.private_key_pem  # Ensure access via the bastion
#    }
#  }

  # Provisioner to copy redis.conf to the instance
  provisioner "file" {
    source      = "redis.conf"
    destination = "/tmp/redis.conf"  # Upload to /tmp directory first
    connection {
      type               = "ssh"
      user               = "ubuntu"
      private_key        = tls_private_key.my_key.private_key_pem
      host               = self.private_ip
      bastion_host       = aws_instance.ml_nginx_server.public_ip
      bastion_user       = "ubuntu"
      bastion_private_key = tls_private_key.my_key.private_key_pem
    }
  }

  # Restart Redis after copying the configuration to final destination
  provisioner "remote-exec" {
    inline = [
# Check for the Redis directory, create if it doesn't exist
      "if [ ! -d /etc/redis ]; then sudo mkdir -p /etc/redis; fi",
      "sudo mv /tmp/redis.conf /etc/redis/redis.conf",
      "sudo systemctl restart redis"
    ]
    connection {
      type               = "ssh"
      user               = "ubuntu"
      private_key        = tls_private_key.my_key.private_key_pem
      host               = self.private_ip
      bastion_host       = aws_instance.ml_nginx_server.public_ip
      bastion_user       = "ubuntu"
      bastion_private_key = tls_private_key.my_key.private_key_pem
    }
  }

  tags = {
    Name = "ml_app_server"
  }
}

resource "aws_instance" "ml_training_server" {
  ami                    = var.ec2_ami
  instance_type          = "p3.2xlarge"
  subnet_id              = aws_subnet.ml_private_subnet_training.id
  vpc_security_group_ids = [aws_security_group.ml_backend_security_group.id]
  key_name               = aws_key_pair.my_key.key_name
  user_data = "${file("ml_model_server.sh")}"

  tags = {
    Name = "ml_training_server"
  }
}

resource "tls_private_key" "my_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "my_key" {
  key_name   = "my_key"
  public_key = tls_private_key.my_key.public_key_openssh
}

output "ec2_key" {
  value = tls_private_key.my_key.private_key_pem
  sensitive = true
}

output "ml_training_server_ip" {
  value = aws_instance.ml_training_server.public_ip
}

output "api_server_ip" {
  value = aws_instance.ml_app_server.private_ip
}

output "monitoring_server" {
  value = aws_instance.monitoring_server.public_ip
}

output "nginx_ip" {
  value = aws_instance.ml_nginx_server.public_ip
}

output "ui_server_ip" {
  value = aws_instance.ml_ui_server.private_ip
}

output "nat_gateway_ip" {
  value = aws_eip.nat_eip.public_ip
}
