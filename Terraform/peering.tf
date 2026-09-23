# =========================================================
# TASK 18 - VPC PEERING
# Connect depi-sec-tools-vpc with the application VPC
# =========================================================

# ---------------------------------------------------------
# 1. Tools VPC
# ---------------------------------------------------------

resource "aws_vpc" "tools" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "depi-sec-tools-vpc"
  }
}


# ---------------------------------------------------------
# 2. Tools Private Subnet
# ---------------------------------------------------------

resource "aws_subnet" "tools_a" {
  vpc_id                  = aws_vpc.tools.id
  cidr_block              = "10.1.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "depi-sec-tools-a"
  }
}


# ---------------------------------------------------------
# 3. Tools Route Table
# ---------------------------------------------------------

resource "aws_route_table" "tools" {
  vpc_id = aws_vpc.tools.id

  tags = {
    Name = "depi-sec-tools-private-rt"
  }
}


# ---------------------------------------------------------
# 4. Associate Tools Subnet with Tools Route Table
# ---------------------------------------------------------

resource "aws_route_table_association" "tools_a" {
  subnet_id      = aws_subnet.tools_a.id
  route_table_id = aws_route_table.tools.id
}


# ---------------------------------------------------------
# 5. VPC Peering
# ---------------------------------------------------------

resource "aws_vpc_peering_connection" "app_tools" {
  vpc_id      = aws_vpc.app.id
  peer_vpc_id = aws_vpc.tools.id

  auto_accept = true

  tags = {
    Name = "depi-sec-app-tools-peering"
  }
}


# ---------------------------------------------------------
# 6. Route - App VPC -> Tools VPC
# ---------------------------------------------------------

resource "aws_route" "app_to_tools" {
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = "10.1.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.app_tools.id
}


# ---------------------------------------------------------
# 7. Route - Tools VPC -> App VPC
# ---------------------------------------------------------

resource "aws_route" "tools_to_app" {
  route_table_id            = aws_route_table.tools.id
  destination_cidr_block    = "10.0.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.app_tools.id
}


# ---------------------------------------------------------
# 8. App Security Group - ICMP from Tools subnet
# ---------------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "app_from_tools_icmp" {
  security_group_id = aws_security_group.app.id
  cidr_ipv4         = "10.1.1.0/24" # أو CIDR الخاص بـ tools-vpc
  ip_protocol       = "icmp"
  from_port         = -1
  to_port           = -1
}

# ---------------------------------------------------------
# 9. App Security Group - HTTP from Tools subnet
# ---------------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "app_from_tools_http" {
  security_group_id = aws_security_group.app.id

  description = "Allow HTTP from depi-sec-tools-a"

  cidr_ipv4   = "10.1.1.0/24"
  ip_protocol = "tcp"

  from_port = 80
  to_port   = 80
}


# ---------------------------------------------------------
# 10. Latest Amazon Linux 2023 AMI
# ---------------------------------------------------------

data "aws_ami" "task18_amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}


# ---------------------------------------------------------
# 11. Monitoring Server in Tools VPC
# ---------------------------------------------------------

resource "aws_instance" "tools_monitoring" {
  ami           = data.aws_ami.task18_amazon_linux_2023.id
  instance_type = "t3.micro"
  subnet_id = aws_subnet.tools_a.id

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  associate_public_ip_address = false

  vpc_security_group_ids = [
    aws_security_group.tools_sg.id
    
  ]

  user_data = <<-EOF
    #!/bin/bash

    dnf install -y curl

    echo "Testing connectivity to application server..."
    curl http://${aws_instance.app_a.private_ip}

    echo "Task 18 peering connectivity test completed."
  EOF

  tags = {
    Name = "depi-sec-tools-monitoring"
  }

  depends_on = [
    aws_route.app_to_tools,
    aws_route.tools_to_app,
    aws_vpc_security_group_ingress_rule.app_from_tools_http
  ]
}

resource "aws_security_group" "tools_sg" {
  name        = "depi-sec-tools-sg"
  description = "Security group for tools monitoring server"
  vpc_id      = aws_vpc.tools.id # أضع هنا اسم VPC الخاصة بـ tools لديك (مثلاً aws_vpc.tools.id)

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "depi-sec-tools-sg"
  }
}
