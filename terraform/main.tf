terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Latest Amazon Linux 2023 AMI
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# Use the account's default VPC to keep the setup simple
data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "web" {
  name_prefix = "visionassist-web-"
  description = "Allow HTTP to VisionAssist"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound traffic (package and image downloads)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Project = "VisionAssist" }
}

resource "aws_instance" "web" {
  ami                    = nonsensitive(data.aws_ssm_parameter.al2023.value)
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.web.id]

  # Installs Docker, builds the image from GitHub and starts the container
  user_data = <<-EOT
    #!/bin/bash
    dnf install -y docker git
    systemctl enable --now docker
    git clone ${var.repo_url} /opt/visionassist
    cd /opt/visionassist
    docker build -t visionassist:1.0 .
    docker run -d --restart unless-stopped -p 80:8080 --name visionassist visionassist:1.0
  EOT
  user_data_replace_on_change = true

  metadata_options {
    http_tokens = "required" # IMDSv2 only
  }

  root_block_device {
    volume_size = 8
    encrypted   = true
  }

  tags = {
    Name    = "visionassist-server"
    Project = "VisionAssist"
  }
}
