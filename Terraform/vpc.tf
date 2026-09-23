# ==========================================
# Task 4 - VPC, Subnets and Routing
# ==========================================

# 1. App VPC
resource "aws_vpc" "app" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "depi-sec-app-vpc"
  }
}


# 2. Public Subnet - AZ A
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.app.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "depi-sec-public-a"
  }
}


# 3. Public Subnet - AZ B
resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.app.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "depi-sec-public-b"
  }
}


# 4. Private Subnet - AZ A
resource "aws_subnet" "private_a" {
  vpc_id                  = aws_vpc.app.id
  cidr_block              = "10.0.11.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "depi-sec-private-a"
  }
}


# 5. Private Subnet - AZ B
resource "aws_subnet" "private_b" {
  vpc_id                  = aws_vpc.app.id
  cidr_block              = "10.0.12.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "depi-sec-private-b"
  }
}


# 6. Internet Gateway
resource "aws_internet_gateway" "app" {
  vpc_id = aws_vpc.app.id

  tags = {
    Name = "depi-sec-app-igw"
  }
}


# 7. Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.app.id

  tags = {
    Name = "depi-sec-public-rt"
  }
}


# 8. Public Internet Route
resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.app.id
}


# 9. Public Subnet A Association
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}


# 10. Public Subnet B Association
resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}


# 11. Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.app.id

  tags = {
    Name = "depi-sec-private-rt"
  }
}


# 12. Private Subnet A Association
resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}


# 13. Private Subnet B Association
resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}