provider "aws" {
  region = var.aws_region
}

// Create VPC

resource "aws_vpc" "palworld_vpc" {
  cidr_block = "10.10.0.0/16"

  tags = {
    Name = "palworld_VPC"
  }
}

// Create Subnet

resource "aws_subnet" "palworld_Publicsubnet" {
  vpc_id     = aws_vpc.palworld_vpc.id
  cidr_block = "10.10.1.0/24"

  tags = {
    Name = "palworld_Publicsubnet"
  }
}

// Create Internet Gateway

resource "aws_internet_gateway" "palworld_igw" {
  vpc_id = aws_vpc.palworld_vpc.id

  tags = {
    Name = "palworld_igw"
  }
}

// Create Route Table

resource "aws_route_table" "palworld_routetable" {
  vpc_id = aws_vpc.palworld_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.palworld_igw.id
  }

  tags = {
    Name = "palworld_routetable"
  }
}

// Associate the subnet with the route table

resource "aws_route_table_association" "pal-rt-association" {
  subnet_id      = aws_subnet.palworld_Publicsubnet.id
  route_table_id = aws_route_table.palworld_routetable.id
}

// Create Security Group

resource "aws_security_group" "palworld_SG" {
  name        = "palworld_SG"
  vpc_id      = aws_vpc.palworld_vpc.id

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [var.home_ip]
  }

    ingress {
    from_port        = 8211
    to_port          = 8211
    protocol         = "udp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = 8211
    to_port          = 8211
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "pal_SG"
  }
}

// Create SSH Key

resource "tls_private_key" "palworldserver" {
  algorithm = "RSA"
  rsa_bits = 4096
}

// Create Private Key Locally

resource "local_file" "palworldserver" {
  content = tls_private_key.palworldserver.private_key_pem
  filename = "palworldserver"
}

// Create AWS Key Pair

resource "aws_key_pair" "palworld_KP" {
  key_name = "palworldserver"
  public_key = tls_private_key.palworldserver.public_key_openssh
}

// Create EC2 Instance

resource "aws_instance" "palworld_server" {
  ami           = var.ami_id # us-east-1
  instance_type = "t2.xlarge"
  key_name   = "palworldserver"
  subnet_id = aws_subnet.palworld_Publicsubnet.id
  vpc_security_group_ids = [aws_security_group.palworld_SG.id]
  associate_public_ip_address = true
  
  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt upgrade -y
              sudo apt install nginx -y
              sudo ufw allow 8211
              sudo useradd -m steam
              EOF
  tags = {
    Name = "Palworld-Server"
  }
}
