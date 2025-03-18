provider "aws" {
    region = "eu-central-1"
  }
  
  resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"
  
    tags = {
      Name = "main-vpc"
    }
  }
  
  resource "aws_subnet" "main" {
    vpc_id            = aws_vpc.main.id
    cidr_block        = "10.0.1.0/24"
    availability_zone = var.availability_zone
  
    tags = {
      Name = "main-subnet"
    }
  }
  
  resource "aws_internet_gateway" "main" {
    vpc_id = aws_vpc.main.id
  
    tags = {
      Name = "main-gateway"
    }
  }
  
  resource "aws_route_table" "main" {
    vpc_id = aws_vpc.main.id
  
    route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.main.id
    }
  
    tags = {
      Name = "main-route-table"
    }
  }
  
  resource "aws_route_table_association" "main" {
    subnet_id      = aws_subnet.main.id
    route_table_id = aws_route_table.main.id
  }
  
  resource "aws_security_group" "allow_all" {
    vpc_id = aws_vpc.main.id
  
    ingress {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  
    ingress {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  
    ingress {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  
    egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  
    tags = {
      Name = "allow_all_sg"
    }
  }
  
  resource "aws_instance" "spot_instance" {
    ami           = var.ami_id
    instance_type = var.instance_type
    key_name      = var.key_name
    subnet_id     = aws_subnet.main.id
    associate_public_ip_address = true
  
    security_groups = [aws_security_group.allow_all.id]
    root_block_device {
      volume_size           = 16    #  Set root volume to 16GB
      volume_type           = "gp3" #  Use gp3 for better performance
      delete_on_termination = true  #  Ensures volume is deleted when the instance is terminated
    }
    # Spot instance configuration
      instance_market_options {
          market_type = "spot"
          spot_options {
            max_price = var.spot_price
          
          }
      }
  
    # User data script
    user_data = <<-EOF
#!/bin/bash

apt update
apt install unzip -y
# Add Docker's official GPG key
echo "Adding Docker's GPG key..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up the Docker stable repository
echo "Setting up the Docker repository..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update the package index again
echo "Updating package index with Docker packages..."
sudo apt-get update -y

# Install Docker
echo "Installing Docker..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Enable and start Docker service
echo "Enabling and starting Docker service..."
sudo systemctl enable docker
sudo systemctl start docker
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

sudo groupadd docker
sudo usermod -aG docker ubuntu
systemctl restart docker.service 
chmod 666 /var/run/docker.sock


# Prepare the `nvme1n1` disk for Docker storage
DEVICE="/dev/nvme1n1"
DOCKER_STORAGE="/docker/storage"

# Check if the device is already formatted
if ! sudo file -s $DEVICE | grep -q "filesystem"; then
    # Format the device with ext4 filesystem
    sudo mkfs.ext4 $DEVICE
fi

# Create the mount point
sudo mkdir -p $DOCKER_STORAGE

# Mount the device
sudo mount $DEVICE $DOCKER_STORAGE

cat > /etc/docker/daemon.json <<EOF2
{
 "data-root": "$DOCKER_STORAGE"
}
EOF2
systemctl restart docker

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version 


# Github Actions runner
mkdir /home/ubuntu/actions-runner && cd /home/ubuntu/actions-runner
# Download the latest runner package
curl -o actions-runner-linux-x64-2.322.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.322.0/actions-runner-linux-x64-2.322.0.tar.gz
# Optional: Validate the hash
echo "b13b784808359f31bc79b08a191f5f83757852957dd8fe3dbfcc38202ccf5768  actions-runner-linux-x64-2.322.0.tar.gz" | shasum -a 256 -c
# Extract the installer
tar xzf ./actions-runner-linux-x64-2.322.0.tar.gz

chown ubuntu:ubuntu -R /home/ubuntu/actions-runner

  
  EOF
  
    tags = {
      Name = "TerraformSpotInstance"
    }
  }
