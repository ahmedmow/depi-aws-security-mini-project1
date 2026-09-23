# ============================================================
# Task 19 - AWS Backup with Vault Lock
# ============================================================

# ------------------------------------------------------------
# AWS Backup Vault
# ------------------------------------------------------------

resource "aws_backup_vault" "main" {
  name = "depi-sec-vault"

  tags = {
    Name = "depi-sec-vault"
  }
}

# ------------------------------------------------------------
# IAM Role for AWS Backup
# ------------------------------------------------------------

resource "aws_iam_role" "backup" {
  name = "depi-sec-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "backup.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "restore" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

# ------------------------------------------------------------
# Backup Plan
# ------------------------------------------------------------

resource "aws_backup_plan" "main" {
  name = "depi-sec-backup-plan"

  rule {
    rule_name         = "depi-sec-daily-backup"
    target_vault_name = aws_backup_vault.main.name

    # 05:00 UTC every day
    schedule = "cron(0 5 * * ? *)"

    start_window      = 60
    completion_window = 180

    lifecycle {
      delete_after = 30
    }
  }

  tags = {
    Name = "depi-sec-backup-plan"
  }
}

# ------------------------------------------------------------
# Backup Selection
# Select resources using the required Project tag
# ------------------------------------------------------------

resource "aws_backup_selection" "main" {
  name         = "depi-sec-project-resources"
  iam_role_arn = aws_iam_role.backup.arn
  plan_id      = aws_backup_plan.main.id

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "Project"
    value = "depi-mini-project-1"
  }
}

# ------------------------------------------------------------
# Vault Lock - Governance Mode
# ------------------------------------------------------------

resource "aws_backup_vault_lock_configuration" "main" {
  backup_vault_name = aws_backup_vault.main.name

  min_retention_days = 7
  max_retention_days = 365

  # Grace period required by Task 19
  changeable_for_days = 3
}