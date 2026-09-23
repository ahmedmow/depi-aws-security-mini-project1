# =========================================================
# TASK 17 - LAMBDA AUTO-REMEDIATION
# =========================================================

# ---------------------------------------------------------
# Lambda IAM Role
# ---------------------------------------------------------

resource "aws_iam_role" "lambda_remediation_role" {
  name = "depi-sec-lambda-remediation-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "lambda.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}


# ---------------------------------------------------------
# Lambda IAM Policy
# ---------------------------------------------------------

resource "aws_iam_role_policy" "lambda_remediation_policy" {
  name = "depi-sec-lambda-remediation-policy"
  role = aws_iam_role.lambda_remediation_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "ec2:DescribeSecurityGroups",
          "ec2:RevokeSecurityGroupIngress"
        ]

        Resource = "*"
      },

      {
        Effect = "Allow"

        Action = [
          "sns:Publish"
        ]

        Resource = aws_sns_topic.depi_sec_alerts.arn
      },

      {
        Effect = "Allow"

        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]

        Resource = "*"
      }
    ]
  })
}


# ---------------------------------------------------------
# Lambda Package
# ---------------------------------------------------------

data "archive_file" "lambda_remediation" {
  type        = "zip"
  source_file = "${path.module}/lambda_remediation.py"
  output_path = "${path.module}/lambda_remediation.zip"
}


# ---------------------------------------------------------
# Lambda Function
# ---------------------------------------------------------

resource "aws_lambda_function" "security_group_remediation" {
  function_name = "depi-sec-sg-auto-remediation"

  role = aws_iam_role.lambda_remediation_role.arn

  runtime = "python3.12"
  handler = "lambda_remediation.lambda_handler"

  filename         = data.archive_file.lambda_remediation.output_path
  source_code_hash = data.archive_file.lambda_remediation.output_base64sha256

  timeout = 30

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.depi_sec_alerts.arn
    }
  }

  depends_on = [
    aws_iam_role_policy.lambda_remediation_policy
  ]
}


# ---------------------------------------------------------
# CloudWatch Log Group for Lambda
# ---------------------------------------------------------

resource "aws_cloudwatch_log_group" "lambda_remediation" {
  name              = "/aws/lambda/depi-sec-sg-auto-remediation"
  retention_in_days = 14
}


# ---------------------------------------------------------
# EventBridge Rule
# ---------------------------------------------------------

resource "aws_cloudwatch_event_rule" "security_group_ingress" {
  name        = "depi-sec-detect-security-group-ingress"
  description = "Detect security group ingress authorization through CloudTrail"

  event_pattern = jsonencode({
    source = [
      "aws.ec2"
    ]

    detail-type = [
      "AWS API Call via CloudTrail"
    ]

    detail = {
      eventSource = [
        "ec2.amazonaws.com"
      ]

      eventName = [
        "AuthorizeSecurityGroupIngress"
      ]
    }
  })
}


# ---------------------------------------------------------
# EventBridge -> Lambda Target
# ---------------------------------------------------------

resource "aws_cloudwatch_event_target" "security_group_remediation" {
  rule = aws_cloudwatch_event_rule.security_group_ingress.name
  arn  = aws_lambda_function.security_group_remediation.arn
}


# ---------------------------------------------------------
# Allow EventBridge to invoke Lambda
# ---------------------------------------------------------
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id = "AllowEventBridgeInvoke"

  action = "lambda:InvokeFunction"

  function_name = aws_lambda_function.security_group_remediation.function_name

  principal = "events.amazonaws.com"

  source_arn = aws_cloudwatch_event_rule.security_group_ingress.arn
}