# ==========================================
# Task 5 - Security Groups
# ==========================================

# 1. ALB Security Group
# The only Security Group open to the Internet
resource "aws_security_group" "alb" {
  name        = "depi-sec-alb-sg"
  description = "Security group for the Application Load Balancer"
  vpc_id      = aws_vpc.app.id

  tags = {
    Name = "depi-sec-alb-sg"
  }
}


resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id

  ip_protocol = "tcp"
  from_port   = 80
  to_port     = 80

  cidr_ipv4 = "0.0.0.0/0"
}


# 2. Application Security Group
resource "aws_security_group" "app" {
  name        = "depi-sec-app-sg"
  description = "Security group for application servers"
  vpc_id      = aws_vpc.app.id

  tags = {
    Name = "depi-sec-app-sg"
  }
}


resource "aws_vpc_security_group_ingress_rule" "app_http" {
  security_group_id = aws_security_group.app.id

  ip_protocol = "tcp"
  from_port   = 80
  to_port     = 80

  referenced_security_group_id = aws_security_group.alb.id
}


# 3. Database Security Group
resource "aws_security_group" "db" {
  name        = "depi-sec-db-sg"
  description = "Security group for RDS database"
  vpc_id      = aws_vpc.app.id

  tags = {
    Name = "depi-sec-db-sg"
  }
}


resource "aws_vpc_security_group_ingress_rule" "db_mysql" {
  security_group_id = aws_security_group.db.id

  ip_protocol = "tcp"
  from_port   = 3306
  to_port     = 3306

  referenced_security_group_id = aws_security_group.app.id
}


# 4. EFS Security Group
resource "aws_security_group" "efs" {
  name        = "depi-sec-efs-sg"
  description = "Security group for EFS"
  vpc_id      = aws_vpc.app.id

  tags = {
    Name = "depi-sec-efs-sg"
  }
}


resource "aws_vpc_security_group_ingress_rule" "efs_nfs" {
  security_group_id = aws_security_group.efs.id

  ip_protocol = "tcp"
  from_port   = 2049
  to_port     = 2049

  referenced_security_group_id = aws_security_group.app.id
}


# ==========================================
# Task 6 - Network ACLs
# ==========================================

# Custom NACL for the two private subnets
resource "aws_network_acl" "private-nacl" {
  vpc_id = aws_vpc.app.id

  tags = {
    Name = "depi-sec-private-nacl"
  }
}


# ==========================================
# Inbound Rules
# ==========================================

# Rule 100 - Allow TCP 80
resource "aws_network_acl_rule" "private_inbound_80" {
  network_acl_id = aws_network_acl.private-nacl.id

  rule_number = 100
  egress      = false
  protocol    = "tcp"
  rule_action = "allow"

  cidr_block = "10.0.0.0/16"
  from_port  = 80
  to_port    = 80
}


# Rule 110 - Allow TCP 443
resource "aws_network_acl_rule" "private_inbound_443" {
  network_acl_id = aws_network_acl.private-nacl.id

  rule_number = 110
  egress      = false
  protocol    = "tcp"
  rule_action = "allow"

  cidr_block = "10.0.0.0/16"
  from_port  = 443
  to_port    = 443
}


# Rule 120 - Allow ephemeral ports
resource "aws_network_acl_rule" "private_inbound_ephemeral" {
  network_acl_id = aws_network_acl.private-nacl.id

  rule_number = 120
  egress      = false
  protocol    = "tcp"
  rule_action = "allow"

  cidr_block = "10.0.0.0/16"
  from_port  = 1024
  to_port    = 65535
}


# Rule 200 - Deny SSH
resource "aws_network_acl_rule" "private_inbound_ssh_deny" {
  network_acl_id = aws_network_acl.private-nacl.id

  rule_number = 200
  egress      = false
  protocol    = "tcp"
  rule_action = "deny"

  cidr_block = "0.0.0.0/0"
  from_port  = 22
  to_port    = 22
}


# ==========================================
# Outbound Rules
# ==========================================

# Rule 100 - Allow all to VPC
resource "aws_network_acl_rule" "private_outbound_vpc" {
  network_acl_id = aws_network_acl.private-nacl.id

  rule_number = 100
  egress      = true
  protocol    = "-1"
  rule_action = "allow"

  cidr_block = "10.0.0.0/16"
}


# Rule 110 - Allow TCP 443 to Internet
resource "aws_network_acl_rule" "private_outbound_443" {
  network_acl_id = aws_network_acl.private-nacl.id

  rule_number = 110
  egress      = true
  protocol    = "tcp"
  rule_action = "allow"

  cidr_block = "0.0.0.0/0"
  from_port  = 443
  to_port    = 443
}


# ==========================================
# Associate NACL with Private Subnets
# ==========================================

resource "aws_network_acl_association" "private_a" {
  network_acl_id = aws_network_acl.private-nacl.id
  subnet_id      = aws_subnet.private_a.id
}


resource "aws_network_acl_association" "private_b" {
  network_acl_id = aws_network_acl.private-nacl.id
  subnet_id      = aws_subnet.private_b.id
}