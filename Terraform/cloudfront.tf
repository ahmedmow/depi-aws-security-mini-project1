# ==========================================
# Task 13 - CloudFront
# ==========================================

# Secret used between CloudFront and ALB
resource "random_password" "origin_verify" {
  length  = 32
  special = false
}


# CloudFront Distribution
resource "aws_cloudfront_distribution" "app" {
  enabled = true

  origin {
    domain_name = aws_lb.app.dns_name
    origin_id   = "depi-sec-alb"

    custom_header {
      name  = "X-Origin-Verify"
      value = random_password.origin_verify.result
    }

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"

      origin_ssl_protocols = [
        "TLSv1.2"
      ]
    }
  }

  default_cache_behavior {
    target_origin_id = "depi-sec-alb"

    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = [
      "GET",
      "HEAD",
      "OPTIONS"
    ]

    cached_methods = [
      "GET",
      "HEAD"
    ]

    forwarded_values {
      query_string = true

      cookies {
        forward = "all"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "depi-sec-cloudfront"
  }
}


