# ==========================================
# Task 3 - Identity & Least Privilege
# ==========================================

# ------------------------------------------
# 1. Account Password Policy
# ------------------------------------------

resource "aws_iam_account_password_policy" "depi_sec" {
  minimum_password_length      = 14
  require_uppercase_characters = true
  require_lowercase_characters = true
  require_numbers              = true
  require_symbols              = true
  max_password_age             = 90
  password_reuse_prevention    = 5
  hard_expiry                  = false
}


# ------------------------------------------
# 2. Developers Group
# ------------------------------------------

resource "aws_iam_group" "developers" {
  name = "depi-sec-developers"
}


# ------------------------------------------
# 3. ReadOnlyAccess for Developers
# ------------------------------------------

resource "aws_iam_group_policy_attachment" "developers_readonly" {
  group      = aws_iam_group.developers.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}


# ------------------------------------------
# 4. Developer User
# ------------------------------------------

resource "aws_iam_user" "developer" {
  name = "depi-dev-1"
}


# Add user to developers group
resource "aws_iam_user_group_membership" "developer" {
  user = aws_iam_user.developer.name

  groups = [
    aws_iam_group.developers.name
  ]
}


# ------------------------------------------
# 5. Console Login Profile
# ------------------------------------------

resource "aws_iam_user_login_profile" "developer" {
  user = aws_iam_user.developer.name

  password_reset_required = true
}


# ------------------------------------------
# 6. S3 Read-Only Custom Policy
# ------------------------------------------

resource "aws_iam_policy" "s3_app_read" {
  name        = "depi-sec-s3-app-read"
  description = "Allow read access only to objects inside the application S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "${aws_s3_bucket.app.arn}/*"
      }
    ]
  })
}
# ------------------------------------------
# 7. EC2 IAM Role
# ------------------------------------------

resource "aws_iam_role" "ec2_role" {
  name = "depi-sec-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}


# ------------------------------------------
# 8. SSM Policy for EC2
# ------------------------------------------

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


# ------------------------------------------
# 9. S3 Read Policy for EC2 Role
# ------------------------------------------

resource "aws_iam_role_policy_attachment" "ec2_s3_read" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_app_read.arn
}


# ------------------------------------------
# 10. EC2 Instance Profile
# ------------------------------------------

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "depi-sec-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

#------------------------------------------------------------------------
#  IAM Policy for CloudTrail ----------> CloudWatch
#------------------------------------------------------------------------ 
data "aws_iam_policy_document" "cloudtrail_cloudwatch" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
    ]
  }
}

resource "aws_iam_role_policy" "cloudtrail_cloudwatch" {
  name   = "depi-sec-cloudtrail-cloudwatch-policy"
  role   = aws_iam_role.cloudtrail_cloudwatch.id
  policy = data.aws_iam_policy_document.cloudtrail_cloudwatch.json
}

#------------------------------------------------------------------------
#  IAM Role for CloudTrail ----------> CloudWatch
#------------------------------------------------------------------------ 
data "aws_iam_policy_document" "cloudtrail_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "cloudtrail_cloudwatch" {
  name               = "depi-sec-cloudtrail-cloudwatch-role"
  assume_role_policy = data.aws_iam_policy_document.cloudtrail_assume_role.json
}

