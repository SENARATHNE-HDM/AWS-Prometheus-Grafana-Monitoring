terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1" # N. Virginia
}

# 1. Default VPC එක ලබා ගැනීම
resource "aws_default_vpc" "default" {}

# 2. Prometheus සහ Grafana සඳහා Security Group එකක් සෑදීම
resource "aws_security_group" "monitoring_sg" {
  name        = "monitoring-project-sg"
  description = "Allow Grafana, Prometheus and SSH traffic"
  vpc_id      = aws_default_vpc.default.id

  # 💻 SSH Port
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 📊 Grafana Port (Dashboard බලන්න)
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 🔥 Prometheus Port (Metrics එකතු කරන්න)
  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 3. Monitoring Server එක නිර්මාණය කිරීම සහ Prometheus + Grafana ඉන්ස්ටෝල් කිරීම
resource "aws_instance" "monitoring_server" {
  ami                    = "ami-0c7217cdde317cfec" # Ubuntu 22.04 LTS
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.monitoring_sg.id]

  # 🐳 Docker හරහා Prometheus සහ Grafana Containers විදිහට එක පාරින් රන් කිරීම:
  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install docker.io -y
              sudo systemctl start docker
              sudo systemctl enable docker

              # Prometheus Container එක පණ ගැන්වීම
              sudo docker run -d --name prometheus -p 9090:9090 prom/prometheus

              # Grafana Dashboard Container එක පණ ගැන්වීම
              sudo docker run -d --name grafana -p 3000:3000 grafana/grafana
              EOF

  tags = {
    Name = "DevOps-Project6-MonitoringServer"
  }
}

# 4. සර්වර් එකේ Public IP එක Output එකක් ලෙස ලබා ගැනීම
output "monitoring_server_ip" {
  value = aws_instance.monitoring_server.public_ip
}