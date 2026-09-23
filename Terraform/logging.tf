# Task 14 - CLOUDTRAIL
# =========================================================

resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/depi-sec/cloudtrail"
  retention_in_days = 14
}

resource "aws_iam_role" "cloudtrail_cw" {
  name = "depi-sec-cloudtrail-cw-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "cloudtrail_cw_policy" {
  name = "depi-sec-cloudtrail-cw-policy"
  role = aws_iam_role.cloudtrail_cw.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
      }
    ]
  })
}

# تصحيح: إضافة policy للـ S3 لتسمح بمرور لوجز CloudTrail
resource "aws_s3_bucket_policy" "logs_policy" {
  bucket = aws_s3_bucket.logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.logs.arn
      },
      {
        Sid       = "AWSCloudTrailWrite"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.logs.arn}/*"
        Condition = {
          StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" }
        }
      }
    ]
  })
}

resource "aws_cloudtrail" "main" {
  name                          = "depi-sec-trail"
  s3_bucket_name                = aws_s3_bucket.logs.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true

  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn   = aws_iam_role.cloudtrail_cw.arn

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["${aws_s3_bucket.app.arn}/"]
    }
  }

  depends_on = [
    aws_s3_bucket_policy.logs_policy
  ]
}

# =========================================================
# Task 15 - VPC FLOW LOGS
# =========================================================

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/depi-sec/vpc/flowlogs"
  retention_in_days = 14
}

resource "aws_iam_role" "vpc_flow_logs_role" {
  name = "depi-sec-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "vpc-flow-logs.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "vpc_flow_logs_policy" {
  name = "depi-sec-vpc-flow-logs-policy"
  role = aws_iam_role.vpc_flow_logs_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "logs:CreateLogStream",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.vpc_flow_logs.arn}:*"
      }
    ]
  })
}

resource "aws_flow_log" "app_vpc_flow_log" {
  vpc_id          = aws_vpc.app.id
  traffic_type    = "ALL"
  iam_role_arn    = aws_iam_role.vpc_flow_logs_role.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs.arn

  depends_on = [
    aws_iam_role_policy.vpc_flow_logs_policy
  ]
}

# =========================================================
# Task 16 - CLOUDWATCH MONITORING & ALARMS
# =========================================================

resource "aws_sns_topic" "depi_sec_alerts" {
  name = "depi-sec-alerts"
}
 resource "aws_sns_topic_subscription" "depi_sec_alert_email" {
  topic_arn = aws_sns_topic.depi_sec_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# 1 - EC2 CPU > 70%
resource "aws_cloudwatch_metric_alarm" "ec2_cpu_high" {
  alarm_name          = "depi-sec-ec2-cpu-high"
  alarm_description   = "EC2 CPUUtilization above 70%"
  comparison_operator = "GreaterThanThreshold"

  metric_name = "CPUUtilization"
  namespace   = "AWS/EC2"
  statistic   = "Average"

  period              = 300
  evaluation_periods  = 2
  threshold           = 70
  datapoints_to_alarm = 2

  dimensions = {
    InstanceId = aws_instance.app_a.id
  }

  alarm_actions      = [aws_sns_topic.depi_sec_alerts.arn]
  treat_missing_data = "notBreaching"
}

# 2 - ALB UnHealthyHostCount > 0
resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  alarm_name          = "depi-sec-alb-unhealthy-hosts"
  alarm_description   = "ALB has unhealthy targets"
  comparison_operator = "GreaterThanThreshold"

  metric_name = "UnHealthyHostCount"
  namespace   = "AWS/ApplicationELB"
  statistic   = "Maximum"

  period             = 300
  evaluation_periods = 1
  threshold          = 0

  dimensions = {
    LoadBalancer = aws_lb.app.arn_suffix
    TargetGroup  = aws_lb_target_group.app.arn_suffix
  }

  alarm_actions      = [aws_sns_topic.depi_sec_alerts.arn]
  treat_missing_data = "notBreaching"
}

# 3 - RDS FreeStorageSpace < 2 GB
resource "aws_cloudwatch_metric_alarm" "rds_free_storage_low" {
  alarm_name          = "depi-sec-rds-free-storage-low"
  alarm_description   = "RDS free storage is below 2 GB"
  comparison_operator = "LessThanThreshold"

  metric_name = "FreeStorageSpace"
  namespace   = "AWS/RDS"
  statistic   = "Average"

  period             = 300
  evaluation_periods = 1
  threshold          = 2147483648

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.app.identifier
  }

  alarm_actions      = [aws_sns_topic.depi_sec_alerts.arn]
  treat_missing_data = "notBreaching"
}

# 4 - CloudTrail Failed Console Login Filter & Alarm
resource "aws_cloudwatch_log_metric_filter" "log_failed_console_login" {
  name           = "depi-sec-failed-console-login"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name

  pattern = "{ ($.eventName = \"ConsoleLogin\") && ($.errorMessage = \"Failed authentication\") }"

  metric_transformation {
    name      = "FailedConsoleLogin"
    namespace = "depi-sec/security"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "failed_console_login" {
  alarm_name          = "depi-sec-failed-console-login"
  alarm_description   = "Three failed AWS Console login attempts in 5 minutes"
  comparison_operator = "GreaterThanOrEqualToThreshold"

  metric_name = "FailedConsoleLogin"
  namespace   = "depi-sec/security"
  statistic   = "Sum"

  period             = 300
  evaluation_periods = 1
  threshold          = 3

  alarm_actions      = [aws_sns_topic.depi_sec_alerts.arn]
  treat_missing_data = "notBreaching"

  tags = {
    Name    = "depi-sec-login-alarm"
    Project = "depi-sec"
  }
}

# =========================================================
# DASHBOARD
# =========================================================

resource "aws_cloudwatch_dashboard" "depi_sec_overview" {
  dashboard_name = "depi-sec-overview"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          title  = "EC2 CPU Utilization"
          region = var.region
          period = 300
          stat   = "Average"
          view   = "timeSeries"

          metrics = [
            [
              "AWS/EC2",
              "CPUUtilization",
              "InstanceId",
              aws_instance.app_a.id
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
         properties = {
          title  = "ALB Unhealthy Hosts"
          region = var.region
          period = 300
          stat   = "Maximum"
          view   = "timeSeries"

          metrics = [
            [
              "AWS/ApplicationELB",
              "UnHealthyHostCount",
              "LoadBalancer",
              aws_lb.app.arn_suffix,
              "TargetGroup",
              aws_lb_target_group.app.arn_suffix
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          title  = "RDS Free Storage"
          region = var.region
          period = 300
          stat   = "Average"
          view   = "timeSeries"

          metrics = [
            [
              "AWS/RDS",
              "FreeStorageSpace",
              "DBInstanceIdentifier",
              aws_db_instance.app.identifier
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6

        properties = {
          title  = "Failed Console Logins"
          region = var.region
          period = 300
          stat   = "Sum"
          view   = "timeSeries"

          metrics = [
            [
              "depi-sec/security",
              "FailedConsoleLogin"
            ]
          ]
        }
      }
    ]
  })
}