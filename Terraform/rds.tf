# ==========================================
# Task 11 - Private RDS MySQL Database
# ==========================================

# DB subnet group using the two private subnets
resource "aws_db_subnet_group" "app" {
  name = "depi-sec-db-subnet-group"

  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]

  tags = {
    Name = "depi-sec-db-subnet-group"
  }
}

# Private MySQL database
resource "aws_db_instance" "app" {
  identifier = "depi-sec-mysql"

  engine         = "mysql"
  engine_version = "8.0"

  instance_class        = "db.t3.micro"
  allocated_storage     = 20
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = "depiapp"
  username = "admin"
  password = random_password.db.result

  db_subnet_group_name = aws_db_subnet_group.app.name

  vpc_security_group_ids = [
    aws_security_group.db.id
  ]

  publicly_accessible = false

  multi_az = false

  skip_final_snapshot       = true
  deletion_protection       = false
  delete_automated_backups  = true
}

# Random password for the database
resource "random_password" "db" {
  length  = 16
  special = true
}

# Store the password in Secrets Manager
resource "aws_secretsmanager_secret" "db" {
  name = "depi-sec-rds-password"
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id

  secret_string = random_password.db.result
}
