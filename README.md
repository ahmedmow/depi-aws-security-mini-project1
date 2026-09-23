# Mini Project 1 - Secure AWS Web Platform (Terraform)

## 1. Project Overview
This project is a complete, secure AWS web platform built for a small company using Terraform. Designed with a Defense-in-Depth architecture, the core application servers and database are isolated inside private subnets without direct internet access. Key security guardrails include keyless remote access, automated cost governance, centralized log auditing, automated threat remediation, and immutable data backups.

---

## 2. Architecture Diagram
[ Internet Users ]
                                         │
                                         ▼
                                 [ CloudFront ] ── (Caching & HTTPS Front Door)
                                         │
                                         │ (Secret Header: X-Origin-Verify)
                                         ▼
                            [ Application Load Balancer ] ── (Public Subnets)
                                         │
                 ┌───────────────────────┴───────────────────────┐
                 ▼                                               ▼
     [ EC2 App Server (AZ-a) ]                       [ EC2 App Server (AZ-b) ] ── (Private Subnets)
                 │                                               │
                 ├───────────────────────┬───────────────────────┤
                 ▼                       ▼                       ▼
            [ RDS MySQL ]            [ EFS ]           [ VPC Endpoints ] ── (Private Subnets)
          (Private Database)     (Shared Files)       (SSM, S3, EC2 Messages)

- Test 6: Attempt to set S3 object public in Console -> Result: Action refused by Block Public Access (PASSED)
- Test 7: Add SSH rule (0.0.0.0/0) to app Security Group -> Result: Automatically revoked by Lambda within 1 min; email sent (PASSED)
- Test 8: Stop Nginx service on one EC2 server -> Result: Target marked Unhealthy; site remains live; alarm email sent (PASSED)
- Test 9: curl app server IP from Tools VPC -> Result: Returns webpage successfully via VPC Peering (PASSED)
- Test 10: Attempt deleting a recovery point in locked vault -> Result: Action refused with Access Denied error (PASSED)

---


## 9. Cost Notes

- The majority of resources fall under the AWS Free Tier.
- Resources with non-free hourly charges:
  * Application Load Balancer (ALB): ~$0.60 per day.
  * VPC Interface Endpoints (3 endpoints): ~$0.65 per day.
- Total actual deployment cost (from AWS Cost Explorer): $X.XX USD.

---

## 10. How to Destroy

To ensure no ongoing charges remain after completing evaluation:

1. Empty all S3 bucket contents (including noncurrent versions):
   aws s3 rm s3://depi-sec-app-<suffix> --recursive
   aws s3 rm s3://depi-sec-logs-<suffix> --recursive

2. Tear down all infrastructure via Terraform:
   terraform destroy -var="alert_email=your-email@example.com" -auto-approve

3. Verify via AWS Console that all instances, databases, and load balancers are removed.

---

## 11. What I Learned

- Designed resilient AWS VPC architectures leveraging multi-AZ private subnets and explicit routing controls.
- Implemented multi-layered defense strategies by combining Security Groups and stateless Network ACLs.
- Eliminated static long-lived credentials and exposed ports by leveraging IAM instance roles, Systems Manager, and interface VPC Endpoints.
- Configured event-driven serverless auto-remediation workflows using CloudTrail, EventBridge, and Lambda.
- Mastered modular Infrastructure as Code (IaC) principles with Terraform for reproducible, auditable cloud deployments.

---

## 12. Known Limitations & Future Improvements

Known Limitations:
- Terraform state is currently stored locally (local state) for demonstration purposes.
- Internal origin communication between CloudFront and ALB relies on HTTP rather than HTTPS.

Future Improvements:
- Migrate state management to an encrypted remote S3 bucket with DynamoDB state locking.
- Attach AWS WAF to CloudFront for OWASP Top 10 web application protection.
- Upgrade inter-VPC network connectivity to AWS Transit Gateway for scalable multi-VPC management.