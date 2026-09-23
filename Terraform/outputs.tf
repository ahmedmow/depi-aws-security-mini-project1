# ---------------------------------------------------------
# 12. Output - Tools Monitoring Server Private IP
# ---------------------------------------------------------

output "tools_monitoring_private_ip" {
  description = "Private IP of the Task 18 monitoring server"
  value       = aws_instance.tools_monitoring.private_ip
}


# ---------------------------------------------------------
# 13. Output - VPC Peering ID
# ---------------------------------------------------------

output "app_tools_peering_id" {
  description = "VPC peering connection ID"
  value       = aws_vpc_peering_connection.app_tools.id
}

output "app_vpc_id" {
  description = "The ID of the main application VPC"
  value       = aws_vpc.app.id
}

# ALB DNS Name
output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = aws_lb.app.dns_name
}

# CloudFront URL
output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.app.domain_name
}

output "rds_endpoint" {
  description = "The connection endpoint for the RDS database"
  value       = aws_db_instance.app.endpoint
}

output "app_bucket_name" {
  description = "Name of the application S3 bucket"
  value       = aws_s3_bucket.app.id
}

output "logs_bucket_name" {
  description = "Name of the logs S3 bucket"
  value       = aws_s3_bucket.logs.id
}