variable "region" {
  type        = string
  default     = "us-east-1"
  description = "AWS Region"
}

variable "project_name" {
  type        = string
  default     = "depi-sec"
  description = "Prefix for all resource names"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "Application VPC CIDR block"
}

variable "alert_email" {
  type        = string
  default     = "ahmedmow212@gmail.com"
  description = "Email address for notifications"
}