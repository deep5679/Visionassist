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

  # Outbound limited to HTTPS and HTTP (package, GitHub and image downloads only).
  # Destination stays 0.0.0.0/0 because GitHub, Docker Hub and AWS mirrors use changing IP ranges.
  egress {
    description = "HTTPS outbound for package and image downloads"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "HTTP outbound for OS package mirrors"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Project = "VisionAssist" }
}

resource "aws_instance" "web" {
  ami                    = nonsensitive(data.aws_ssm_parameter.al2023.value)
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.web.id]

  # No auto-assigned public IP: the public address is attached as an Elastic IP below
  associate_public_ip_address = false

  # Installs Docker, builds the image from GitHub and starts the container
  user_data = <<-EOT
    #!/bin/bash
    # Wait until the Elastic IP is attached and the internet is reachable
    until curl -s -m 5 -o /dev/null https://github.com; do sleep 5; done
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

# Stable public address for the website (the server is intentionally public)
resource "aws_eip" "web" {
  domain   = "vpc"
  instance = aws_instance.web.id

  tags = {
    Name    = "visionassist-eip"
    Project = "VisionAssist"
  }
}
