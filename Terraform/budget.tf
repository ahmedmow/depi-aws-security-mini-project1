# ==========================================
# Task 2 - Cost Governance
# ==========================================

# -------------------------------------------------
# Policy that denies expensive resource creation
# -------------------------------------------------
resource "aws_iam_policy" "deny_expensive" {
  name        = "depi-sec-deny-expensive"
  description = "Deny EC2 instance launches and RDS DB creation"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Deny"

        Action = [
          "ec2:RunInstances",
          "rds:CreateDBInstance"
        ]

        Resource = "*"
      }
    ]
  })
}


# -------------------------------------------------
# IAM role assumed by AWS Budgets
# -------------------------------------------------
resource "aws_iam_role" "budgets" {
  name = "depi-sec-budgets-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "budgets.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}


# -------------------------------------------------
# Permissions required by AWS Budgets
# -------------------------------------------------
resource "aws_iam_role_policy" "budgets" {
  name = "depi-sec-budgets-policy"
  role = aws_iam_role.budgets.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "iam:AttachGroupPolicy",
          "iam:DetachGroupPolicy"
        ]

        Resource = "*"
      }
    ]
  })
}


# -------------------------------------------------
# Monthly $10 budget
# -------------------------------------------------
resource "aws_budgets_budget" "monthly" {
  name         = "depi-sec-monthly"
  budget_type  = "COST"
  limit_amount = "10"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  # 80% actual cost
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }

  # 100% forecasted cost
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.alert_email]
  }
}


# -------------------------------------------------
# Budget action at 90%
# Attach deny policy to the developers group
# -------------------------------------------------
resource "aws_budgets_budget_action" "deny_expensive" {
  budget_name        = aws_budgets_budget.monthly.name
  action_type        = "APPLY_IAM_POLICY"
  approval_model     = "AUTOMATIC"
  notification_type  = "ACTUAL"
  execution_role_arn = aws_iam_role.budgets.arn

  action_threshold {
    action_threshold_type  = "PERCENTAGE"
    action_threshold_value = 90
  }

  definition {
    iam_action_definition {
      policy_arn = aws_iam_policy.deny_expensive.arn

      groups = [
        "depi-sec-developers"
      ]
    }
  }

  subscriber {
    address           = var.alert_email
    subscription_type = "EMAIL"
  }

  depends_on = [
    aws_iam_role_policy.budgets
  ]
}
