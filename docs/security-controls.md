 # AWS Security Controls and Guardrails

## 1. Governance and Cost Controls

### AWS Budgets and Automated Actions
- Purpose: Prevent uncontrolled AWS spending and mitigate account-hijacking resource consumption.
- Implementation: An AWS Budget monitors account costs against a pre-set threshold. An automated Budget Action attaches an IAM deny policy to stop expensive EC2 instance provisioning if the limit is breached.

---

## 2. Identity and Access Management (IAM)

### Least-Privilege IAM Roles
- Purpose: Enforce zero-trust principles and restrict EC2 instance permissions to required services only.
- Implementation: EC2 app servers use IAM Instance Profiles with permissions limited to Systems Manager (SSM), S3 access, CloudWatch Logs, and EFS operations. No permanent IAM user access keys are stored on servers.

### Keyless Administration via SSM Session Manager
- Purpose: Eliminate SSH key pair management and close port 22.
- Implementation: Remote management is handled via AWS Systems Manager Session Manager over private VPC Interface Endpoints.

---

## 3. Network and Perimeter Protection

### CloudFront Custom Secret Header Enforcement
- Purpose: Prevent attackers from bypassing CloudFront to attack the Application Load Balancer directly.
- Implementation: CloudFront injects a custom secret header (X-Origin-Verify) into requests sent to the ALB. The ALB evaluates the header and drops any request missing the expected secret with a 403 Forbidden status.

### Multi-Layer Security Groups and Stateless NACLs
- Purpose: Restrict network traffic between application layers using Defense-in-Depth.
- Implementation: Security Groups enforce stateful ingress filtering allowing ALB access only on port 80/443 and RDS access on port 3306 strictly from app servers. Stateless Network ACLs act as a secondary boundary on subnets.

---

## 4. Data Protection and Storage Security

### Amazon S3 Block Public Access and Bucket Policies
- Purpose: Prevent public exposure of application data and system logs.
- Implementation: S3 Block Public Access is enabled at the bucket level. Encryption at rest (AES-256 / SSE-S3) and TLS-only bucket policies enforce data security.


### Database and File System Isolation
- Purpose: Secure application state and persistent storage.
- Implementation: RDS MySQL and EFS file systems reside exclusively in private subnets with encryption at rest enabled using KMS.

---

## 5. Logging, Auditing, and Automated Remediation

### CloudTrail Validation and Centralized Logging
- Purpose: Maintain immutable audit records of all API calls across the AWS account.
- Implementation: CloudTrail sends API logs to an S3 log bucket with Log File Integrity Validation enabled to detect log tampering. VPC Flow Logs capture network traffic details.


### Automated Security Remediation via EventBridge and Lambda
- Purpose: Detect and fix unauthorized security group rule modifications in real time.
- Implementation: CloudTrail triggers an EventBridge Rule when an inbound security group rule (such as open SSH port 22) is created. EventBridge invokes an AWS Lambda function to revoke the risky rule immediately and notify admins via SNS.

---

## 6. Backup, Recovery, and Compliance

### AWS Backup Vault Lock in Governance Mode
 Purpose: Protect backups against ransomware and accidental or unauthorized deletion.
- Implementation: Centralized backup plans automate daily snapshots of EBS volumes, RDS instances, and EFS file systems. The Backup Vault is locked with Vault Lock in Governance Mode to reject deletion requests.
