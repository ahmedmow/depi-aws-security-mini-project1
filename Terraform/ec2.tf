# ==========================================
# Task 8 - EC2 Servers with Session Manager
# ==========================================


# ==========================================
# 1. Latest Amazon Linux 2023 AMI
# ==========================================

data "aws_ami" "amazon_linux_2023" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}


# ==========================================
# 2. Web Server - Private A
# ==========================================

resource "aws_instance" "app_a" {
  ami = data.aws_ami.amazon_linux_2023.id

  instance_type = "t3.micro"

  subnet_id = aws_subnet.private_a.id

  vpc_security_group_ids = [
    aws_security_group.app.id
  ]

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  associate_public_ip_address = false
  root_block_device {
    encrypted   = true
    volume_type = "gp3"
  }

  user_data = <<-EOF
  #!/bin/bash

  dnf install -y nginx
  dnf install -y amazon-efs-utils

  systemctl enable nginx
  systemctl start nginx

  echo "Server AZ: us-east-1a" > /usr/share/nginx/html/index.html

  mkdir -p /mnt/shared

  mount -t efs -o tls,accesspoint=${aws_efs_access_point.app_data.id} ${aws_efs_file_system.shared.id}:/ /mnt/shared
EOF

  tags = {
    Name = "depi-sec-app-a"
  }
}


# ==========================================
# 3. Web Server - Private B
# ==========================================

resource "aws_instance" "app_b" {
  ami = data.aws_ami.amazon_linux_2023.id

  instance_type = "t3.micro"

  subnet_id = aws_subnet.private_b.id

  vpc_security_group_ids = [
    aws_security_group.app.id
  ]

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  associate_public_ip_address = false
  root_block_device {
    encrypted   = true
    volume_type = "gp3"
  }


  user_data = <<-EOF
  #!/bin/bash

  dnf install -y nginx
  dnf install -y amazon-efs-utils

  systemctl enable nginx
  systemctl start nginx

  echo "Server AZ: us-east-1b" > /usr/share/nginx/html/index.html

  mkdir -p /mnt/shared

  mount -t efs -o tls,accesspoint=${aws_efs_access_point.app_data.id} ${aws_efs_file_system.shared.id}:/ /mnt/shared
EOF

  tags = {
    Name = "depi-sec-app-b"
  }
}