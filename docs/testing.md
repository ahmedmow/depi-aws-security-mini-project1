# Security Verification and Testing Guide

## 1. Testing Framework Overview

To validate the security controls of the AWS platform, a set of 10 verification tests was executed following the completion of the Terraform deployment. Each test targets a specific architectural layer to confirm that security guardrails function as designed.

---

## 2. Test Execution and Verification Log

### Test 01: Direct Application Load Balancer Access
- Target Component: Application Load Balancer (ALB)
- Executed Command:
  curl -I http://<ALB-DNS-NAME>.amazonaws.com
- Expected Result: HTTP/1.1 403 Forbidden
- Test Outcome: PASSED. Direct internet access to origin ALB is blocked due to the missing X-Origin-Verify secret header.

### Test 02: CloudFront HTTPS Access
- Target Component: Amazon CloudFront Distribution
- Executed Command:
  curl -I https://<CLOUDFRONT-DISTRIBUTION-ID>.cloudfront.net
- Expected Result: HTTP/2 200 OK
- Test Outcome: PASSED. Requests routed via CloudFront successfully include the secret header and return the application webpage over TLS.

### Test 03: External SSH Access to Private EC2 Instances
- Target Component: Private Subnet EC2 App Servers
- Executed Command:
  ssh -i key.pem ec2-user@<PRIVATE-EC2-IP> -o ConnectTimeout=5
- Expected Result: Connection timeout / unreachable
- Test Outcome: PASSED. Public SSH access is denied. Inbound flow logs confirm traffic drops (REJECT status).

### Test 04: External Database Connectivity
- Target Component: Amazon RDS MySQL Database
- Executed Command:
  mysql -h <RDS-ENDPOINT> -u admin -p -P 3306
- Expected Result: Connection timeout / host unreachable
- Test Outcome: PASSED. The database instance rejects connections outside the designated private subnets.

### Test 05: Internal Database Connectivity from App Server
- Target Component: RDS MySQL via EC2 App Instance
- Execution Method: Executed via Systems Manager Session Manager shell on EC2.
- Executed Command:
  nc -zv <RDS-ENDPOINT> 3306
- Expected Result: Connection to <RDS-ENDPOINT> 3306 port [tcp/mysql] succeeded!
- Test Outcome: PASSED. Security Group ingress rules allow port 3306 traffic exclusively from private app instances.

### Test 06: S3 Bucket Public Access Block
- Target Component: Amazon S3 Log / Data Buckets
- Executed Command:
  aws s3api put-object-acl --bucket <BUCKET-NAME> --key test.txt --acl public-read
- Expected Result: An error occurred (AccessDenied) when calling the PutObjectAcl operation: Access Denied
- Test Outcome: PASSED. S3 Block Public Access configurations prevent public ACL assignments.

### Test 07: Security Group Insecure Rule Auto-Remediation
- Target Component: EventBridge Rule & Lambda Remediation Function
- Execution Steps:
  1. Manually injected an inbound SSH rule (0.0.0.0/0:22) into the app Security Group.
  2. Observed CloudTrail event capturing AuthorizeSecurityGroupIngress.
- Expected Result: EventBridge triggers Lambda to revoke the rule automatically within 60 seconds and publishes an SNS notification.
- Test Outcome: PASSED. Risky rule was revoked and removed automatically.

### Test 08: High-Availability and ALB Health Checks
- Target Component: Nginx Web Server & Target Groups
- Execution Steps: Stopped the Nginx service on instance AZ-a via SSM.
- Expected Result: ALB marks target as Unhealthy, routes all traffic to AZ-b, and CloudWatch alarm fires.
- Test Outcome: PASSED. Application remained reachable via CloudFront without service downtime.

### Test 09: Private VPC Peering Access from Tools VPC
- Target Component: Tools VPC Monitoring Instance
- Execution Method: Executed from depi-sec-tools-a instance via SSM.
- Executed Command:
  curl -I http://<PRIVATE-EC2-APP-IP>
- Expected Result: HTTP/1.1 200 OK
- Test Outcome: PASSED. Traffic travels privately across the VPC Peering connection without exposure to the internet.
### Test 10: Immutable Backup Protection (Vault Lock)
- Target Component: AWS Backup Vault
- Executed Command:
  aws backup delete-recovery-point --backup-vault-name <VAULT-NAME> --recovery-point-arn <ARN>
- Expected Result: An error occurred (AccessDeniedException) when calling DeleteRecoveryPoint: Recovery point cannot be deleted because the vault is locked
- Test Outcome: PASSED. Backup Vault Lock prevents backup deletion.

---

## 3. Summary Matrix

- Test 01: ALB Direct Access -> Expected: 403 Forbidden -> Result: PASSED
- Test 02: CloudFront Access -> Expected: 200 OK -> Result: PASSED
- Test 03: Public SSH Access -> Expected: Timeout -> Result: PASSED
- Test 04: Public RDS Access -> Expected: Timeout -> Result: PASSED
- Test 05: Private App to RDS Access -> Expected: Connected -> Result: PASSED
- Test 06: S3 Make Public -> Expected: Access Denied -> Result: PASSED
- Test 07: Security Group Auto-Remediation -> Expected: Rule Revoked -> Result: PASSED
- Test 08: ALB Failover -> Expected: Healthy Failover -> Result: PASSED
- Test 09: VPC Peering Routing -> Expected: 200 OK -> Result: PASSED
- Test 10: Delete Backup Point -> Expected: Access Denied -> Result: PASSED