
<div align="center">

# 🔐 Mini Project 1 — Secure AWS Web Platform

### Infrastructure as Code • AWS Security • Terraform

<p>
  <strong>☁️ AWS Cloud</strong> &nbsp;
  <strong>⚙️ Terraform >= 1.6</strong> &nbsp;
  <strong>🛡️ Security First</strong> &nbsp;
  <strong>🎓 DEPI Cloud Security</strong>
</p>

<p>
  A secure, highly structured AWS web platform built entirely with
  <strong>Terraform</strong>, following a defense-in-depth security model.
</p>

</div>

---

## 📌 1. Project Overview

This project implements a small but secure company web platform on AWS using Terraform.

The platform is designed around three core requirements:

- 🌐 The web application must be reachable from the Internet.
- 🔒 Application servers and the database must remain private.
- 🛡️ AWS activity, network traffic, performance, automated remediation, and backups must be monitored and protected.

The infrastructure is completely managed as **Infrastructure as Code (IaC)** using Terraform.

The project combines networking, IAM, storage, compute, monitoring, logging, automation, backup, and security controls into one integrated AWS environment.

### 🎯 Main Objectives

| Objective | Implementation |
|:---|:---|
| Secure network architecture | VPC, public/private subnets, route tables |
| Controlled Internet access | CloudFront + Application Load Balancer |
| Private application servers | EC2 in private subnets |
| Secure administration | AWS Systems Manager Session Manager |
| Private database | Amazon RDS MySQL |
| Shared storage | Amazon EFS |
| Secure object storage | Amazon S3 |
| Network protection | Security Groups + NACLs |
| Private AWS connectivity | VPC Endpoints |
| Activity auditing | AWS CloudTrail |
| Network visibility | VPC Flow Logs |
| Monitoring | Amazon CloudWatch + SNS |
| Automated security response | EventBridge + Lambda |
| Private VPC-to-VPC communication | VPC Peering |
| Data protection | AWS Backup + Vault Lock |

---

## 🏗️ 2. Architecture Diagram

### High-Level Architecture

```text
                         ┌──────────────────────┐
                         │      Internet        │
                         │       Users          │
                         └──────────┬───────────┘
                                    │
                                    ▼
                         ┌──────────────────────┐
                         │      CloudFront      │
                         │  HTTPS / Caching     │
                         └──────────┬───────────┘
                                    │
                              Secret Header
                                    │
                                    ▼
                 ┌────────────────────────────────────┐
                 │          Application VPC            │
                 │             10.0.0.0/16             │
                 │                                    │
                 │   ┌────────────────────────────┐   │
                 │   │       Public Subnets       │   │
                 │   │                            │   │
                 │   │  ┌──────────────────────┐  │   │
                 │   │  │ Application Load     │  │   │
                 │   │  │ Balancer             │  │   │
                 │   │  └──────────┬───────────┘  │   │
                 │   └─────────────┼──────────────┘   │
                 │                 │                  │
                 │   ┌─────────────┴──────────────┐   │
                 │   │      Private Subnets       │   │
                 │   │                            │   │
                 │   │  ┌─────────┐  ┌─────────┐ │   │
                 │   │  │ EC2-A   │  │ EC2-B   │ │   │
                 │   │  │ Nginx   │  │ Nginx   │ │   │
                 │   │  └────┬────┘  └────┬────┘ │   │
                 │   │       │              │      │   │
                 │   │       ├──────┬───────┤      │   │
                 │   │       │      │              │   │
                 │   │  ┌────▼────┐ │ ┌─────────┐ │   │
                 │   │  │   EFS   │ │ │   RDS   │ │   │
                 │   │  │ Shared  │ │ │ MySQL   │ │   │
                 │   │  │ Storage │ │ │ Private │ │   │
                 │   │  └─────────┘ │ └─────────┘ │   │
                 │   └────────────────────────────┘   │
                 │                                    │
                 │  VPC Endpoints → S3 / SSM Services │
                 └────────────────────────────────────┘
                                    │
                              VPC Peering
                                    │
                                    ▼
                 ┌────────────────────────────────────┐
                 │             Tools VPC               │
                 │              10.1.0.0/16             │
                 │                                    │
                 │        ┌──────────────────┐        │
                 │        │ Monitoring EC2    │        │
                 │        │ Private Subnet    │        │
                 │        └──────────────────┘        │
                 └────────────────────────────────────┘


       ┌─────────────────────────────────────────────────────┐
       │                 Security & Observability             │
       │                                                     │
       │ CloudTrail │ VPC Flow Logs │ CloudWatch │ SNS      │
       │ EventBridge │ Lambda │ AWS Backup │ Vault Lock     │
       └─────────────────────────────────────────────────────┘
```

### 🔄 Traffic Flow

```text
Internet User
      │
      ▼
CloudFront
      │
      │ Secret Origin Header
      ▼
Application Load Balancer
      │
      ▼
Private EC2 Servers
      │
      ├──────────────► EFS
      │
      └──────────────► RDS MySQL
```

The application servers, RDS database, and EFS file system are located in private subnets and do not receive public IP addresses.

Administrative access is performed through AWS Systems Manager Session Manager instead of SSH.

The design uses VPC endpoints so private EC2 instances can communicate with required AWS services without requiring a NAT Gateway or Internet route.

---

## 🌐 3. Network Design

<div align="center">

### 🏗️ Two-VPC Secure Architecture

<table>
<tr>
<th>VPC</th>
<th>CIDR</th>
<th>Purpose</th>
</tr>
<tr>
<td><code>depi-sec-app-vpc</code></td>
<td><code>10.0.0.0/16</code></td>
<td>Main application network</td>
</tr>
<tr>
<td><code>depi-sec-tools-vpc</code></td>
<td><code>10.1.0.0/16</code></td>
<td>Monitoring / tools network</td>
</tr>
</table>

<br>

<strong>AWS Region:</strong> <code>us-east-1</code><br>
<strong>Availability Zones:</strong> <code>us-east-1a</code> • <code>us-east-1b</code><br>
<strong>Resource Prefix:</strong> <code>depi-sec</code>

</div>

---

### 🔵 Application VPC

<table>
<tr>
<th>Subnet</th>
<th>CIDR</th>
<th>Availability Zone</th>
<th>Type</th>
<th>Main Resources</th>
</tr>
<tr>
<td><code>depi-sec-public-a</code></td>
<td><code>10.0.1.0/24</code></td>
<td><code>us-east-1a</code></td>
<td>🌐 Public</td>
<td>ALB</td>
</tr>
<tr>
<td><code>depi-sec-public-b</code></td>
<td><code>10.0.2.0/24</code></td>
<td><code>us-east-1b</code></td>
<td>🌐 Public</td>
<td>ALB</td>
</tr>
<tr>
<td><code>depi-sec-private-a</code></td>
<td><code>10.0.11.0/24</code></td>
<td><code>us-east-1a</code></td>
<td>🔒 Private</td>
<td>EC2 / RDS / EFS</td>
</tr>
<tr>
<td><code>depi-sec-private-b</code></td>
<td><code>10.0.12.0/24</code></td>
<td><code>us-east-1b</code></td>
<td>🔒 Private</td>
<td>EC2 / RDS / EFS</td>
</tr>
</table>

**VPC:** <code>depi-sec-app-vpc</code>  
**CIDR:** <code>10.0.0.0/16</code>

> **Public vs Private:** A subnet is considered public only when its route table contains a route to an Internet Gateway (IGW). The subnet name itself does not make it public.

---

### 🌐 Public Routing

The two public subnets use a public route table containing:

| Destination | Target |
|:---:|:---|
| <code>10.0.0.0/16</code> | Local |
| <code>0.0.0.0/0</code> | Internet Gateway |

**Purpose:** Allow the Application Load Balancer to receive Internet traffic.

---

### 🔒 Private Routing

The private subnets use a private route table containing:

| Destination | Target |
|:---:|:---|
| <code>10.0.0.0/16</code> | Local |

There is **no Internet Gateway route** and **no NAT Gateway** for the private subnets.

**Private resources:**

- EC2 application servers
- RDS database
- EFS file system

---

### 🛠️ Tools VPC

<table>
<tr>
<th>VPC</th>
<th>CIDR</th>
<th>Subnet</th>
<th>Subnet CIDR</th>
<th>Availability Zone</th>
<th>Type</th>
<th>Purpose</th>
</tr>
<tr>
<td><code>depi-sec-tools-vpc</code></td>
<td><code>10.1.0.0/16</code></td>
<td><code>depi-sec-tools-a</code></td>
<td><code>10.1.1.0/24</code></td>
<td><code>us-east-1a</code></td>
<td>🔒 Private</td>
<td>Monitoring server</td>
</tr>
</table>

The Tools VPC is connected to the Application VPC using **VPC Peering**.

```text
┌──────────────────────────────────────┐
│          Application VPC             │
│            10.0.0.0/16               │
│                                      │
│  Public-A          Public-B          │
│  10.0.1.0/24       10.0.2.0/24       │
│      │                  │             │
│     ALB                ALB            │
│      │                  │             │
│  Private-A         Private-B          │
│  10.0.11.0/24      10.0.12.0/24      │
│      │                  │             │
│     EC2                EC2            │
│      │                  │             │
│     RDS                EFS            │
└───────────────┬──────────────────────┘
                │
          VPC Peering
                │
┌───────────────┴──────────────────────┐
│             Tools VPC                │
│             10.1.0.0/16              │
│                                      │
│      Tools-A / Monitoring            │
│          10.1.1.0/24                 │
└──────────────────────────────────────┘
```

---

### 🔗 Peering Routes

Both VPCs contain routes for the other VPC:

| VPC | Destination | Target |
|:---|:---:|:---|
| Application VPC | <code>10.1.0.0/16</code> | VPC Peering |
| Tools VPC | <code>10.0.0.0/16</code> | VPC Peering |

This allows the monitoring server in the Tools VPC to communicate with the private application resources through the peering connection.

---

### 🔐 Network Traffic Flow

```text
User
  │
  ▼
CloudFront
  │
  │ Secret Origin Header
  ▼
Public ALB
  │
  ▼
Private EC2
  │
  ├──► RDS
  │
  └──► EFS
```

**Direct Internet → EC2 access is not available.**

The EC2 instances have:

- No public IP
- No SSH access
- No port <code>22</code>
- Private subnet placement

Management access is performed through **AWS Systems Manager Session Manager** using VPC interface endpoints.

> **Design principle:** Internet-facing traffic terminates at the ALB, while application servers, database, and shared storage remain inside private subnets.

---

## 🛡️ 4. Security Controls

| Control | AWS Service | What it stops |
|:---|:---|:---|
| IAM password policy | IAM | Weak passwords and long-lived passwords |
| Least-privilege IAM group | IAM | Unnecessary permissions |
| EC2 IAM role | IAM | Hard-coded AWS access keys on EC2 |
| Public/private subnet separation | VPC | Direct Internet access to private resources |
| Security Groups | VPC | Unwanted network traffic between tiers |
| No inbound port 22 | Security Groups | Direct SSH access |
| Network ACL | VPC | Additional subnet-level traffic control |
| S3 Gateway Endpoint | VPC | Need for Internet access to reach S3 |
| SSM Interface Endpoints | VPC | Need for Internet access for Session Manager |
| No public IP on EC2 | EC2 | Direct Internet access to application servers |
| EBS encryption | EBS | Unencrypted EC2 root volumes |
| EFS encryption | EFS | Unencrypted shared storage |
| S3 Block Public Access | S3 | Public bucket/object access |
| S3 encryption | S3 | Unencrypted objects at rest |
| S3 SecureTransport policy | S3 | Unencrypted HTTP requests |
| Private RDS | RDS | Direct Internet access to the database |
| RDS encryption | RDS | Unencrypted database storage |
| ALB | Elastic Load Balancing | Direct exposure of EC2 servers |
| CloudFront origin header | CloudFront + ALB | Direct ALB access without the expected header |
| CloudTrail | CloudTrail | Missing API activity evidence |
| VPC Flow Logs | VPC | Missing network traffic records |
| CloudWatch alarms | CloudWatch | Missing monitoring and alerting |
| Lambda remediation | Lambda + EventBridge | Open SSH/RDP rules remaining in a Security Group |
| VPC Peering | VPC | Provides private connectivity between the two VPCs |
| AWS Backup | AWS Backup | Missing backups |
| Vault Lock | AWS Backup | Early deletion of protected recovery points |
| AWS Budget action | AWS Budgets + IAM | New expensive resources after the budget threshold |

### 🔗 Security Group Chain

```text
Internet
    |
    v
depi-sec-alb-sg
HTTP 80 from 0.0.0.0/0
    |
    v
depi-sec-app-sg
HTTP 80 from ALB Security Group
    |
    +------------------+
    |                  |
    v                  v
depi-sec-db-sg     depi-sec-efs-sg
TCP 3306           TCP 2049
from app SG        from app SG
```

> **No Security Group contains an inbound rule for port 22.**

---

## ⚙️ 5. Prerequisites

Before deployment, install and configure:

### Terraform

Terraform version:

```text
>= 1.6
```

### AWS Provider

```text
hashicorp/aws ~> 5.0
```

### AWS CLI

The AWS CLI must be installed and configured with credentials that have the permissions required to create the AWS resources used by this project.

Verify the configuration:

```bash
aws sts get-caller-identity
```

### Required Configuration

The project uses:

```text
Region: us-east-1

Availability Zones:
  us-east-1a
  us-east-1b
```

The Terraform variables include:

```text
project_name
region
vpc_cidr
alert_email
```

### Default Tags

```hcl
default_tags {
  tags = {
    Project     = "depi-mini-project-1"
    Owner       = "<your-name>"
    Environment = "lab"
    ManagedBy   = "terraform"
  }
}
```

> ⚠️ **Never put AWS access keys inside Terraform code.**

> ⚠️ **Never commit `terraform.tfstate` to GitHub because the state can contain the database password.**

---

## 🚀 6. How to Deploy

Move into the Terraform directory:

```bash
cd terraform
```

### Initialize Terraform

```bash
terraform init
```

### Validate the Configuration

```bash
terraform validate
```

Expected result:

```text
Success! The configuration is valid.
```

### Review the Plan

```bash
terraform plan
```

### Apply the Infrastructure

```bash
terraform apply
```

Review the Terraform plan and type:

```text
yes
```

### Variables

The project uses the following variables:

| Variable | Description |
|:---|:---|
| <code>project_name</code> | Project name |
| <code>region</code> | AWS Region |
| <code>vpc_cidr</code> | Application VPC CIDR |
| <code>alert_email</code> | Email used for alerts |

Example:

```bash
terraform apply \
  -var="project_name=depi-mini-project-1" \
  -var="region=us-east-1" \
  -var="vpc_cidr=10.0.0.0/16" \
  -var="alert_email=YOUR_EMAIL"
```

> **Do not put secrets directly into Terraform source files.**

---

## 🧪 7. How to Verify

The following tests are taken from Task 20.

| # | Test | Expected Result |
|:---:|:---|:---|
| 1 | Open the ALB DNS name directly in a browser | <code>403 Forbidden</code> |
| 2 | Open the CloudFront URL | Page loads over HTTPS |
| 3 | Try to SSH to a private instance IP | Timeout and a <code>REJECT</code> line in Flow Logs |
| 4 | Connect to RDS from your laptop | Timeout |
| 5 | Connect to RDS from an application server | Success |
| 6 | Make an S3 object public in the Console | Refused by Block Public Access |
| 7 | Add SSH <code>0.0.0.0/0</code> to the app Security Group | Removed by Lambda within a minute and email received |
| 8 | Stop nginx on one server | Target becomes unhealthy, site still works, alarm email |
| 9 | Curl an app server from the Tools VPC | Page returned |
| 10 | Delete a recovery point in the locked vault | Access denied |

### 📸 Verification Evidence

Each test should be supported by the corresponding screenshot.

For tests involving two sides, show both sides of the test.

Examples:

- ALB direct access → `403`
- CloudFront access → successful page
- RDS from outside → failed
- RDS from inside → successful
- Security Group rule before remediation → rule exists
- Security Group rule after remediation → rule removed

---

## 📸 8. Screenshots

Screenshots should show the full browser window, including the AWS Console header and Region.

Do not show account IDs, email addresses, access keys, or other sensitive information.

Use PNG files and organize them by task.

### Recommended Structure

```text
screenshots/
├── 01-budget/
├── 02-iam/
├── 03-vpc/
├── 04-routing/
├── 05-security-groups/
├── 06-nacl/
├── 07-endpoints/
├── 08-ec2/
├── 09-efs/
├── 10-s3/
├── 11-rds/
├── 12-alb/
├── 13-cloudfront/
├── 14-cloudtrail/
├── 15-flow-logs/
├── 16-cloudwatch/
├── 17-remediation/
├── 18-peering/
├── 19-backup/
└── 20-testing/
```

### Required Evidence

| Task | Screenshot Evidence |
|:---|:---|
| Task 2 | Budget overview and budget action |
| Task 3 | IAM role trust policy and custom policy |
| Task 4 | Public and private route tables |
| Task 5 | Security Group rules with Security Group as source |
| Task 6 | NACL rules |
| Task 7 | VPC endpoints and updated private route table |
| Task 8 | Session Manager shell and no public IP |
| Task 9 | Shared EFS file from both servers and encrypted volumes |
| Task 10 | Block Public Access and refused public-access attempt |
| Task 11 | RDS private connectivity and inside/outside connection tests |
| Task 12 | Healthy and unhealthy targets |
| Task 13 | CloudFront successful access and ALB `403` |
| Task 14 | CloudTrail event showing identity |
| Task 15 | Flow Log `REJECT` |
| Task 16 | Dashboard, alarm and email |
| Task 17 | Security Group rule before/after Lambda remediation |
| Task 18 | Peering routes and successful curl |
| Task 19 | Locked vault, completed backup and refused deletion |
| Task 20 | Clean account after destroy and Cost Explorer total |

### Screenshot Naming

Use a numbered filename that explains what the image shows.

Examples:

```text
01-budget-overview.png
02-budget-action.png
03-iam-role-trust-policy.png
04-public-route-table.png
05-private-route-table.png
```

Every screenshot should have a caption explaining what it proves.

---

## 💰 9. Cost Notes

Most of the project is inside the AWS Free Tier, but the following resources are not free:

| Resource | Approximate Cost | Project Action |
|:---|:---:|:---|
| Application Load Balancer | ~$0.60/day | Destroy when finished working |
| 3 VPC Interface Endpoints | ~$0.65/day | Destroy when finished working |
| NAT Gateway | ~$1.10/day | Not used in this project |

The project intentionally does not use a NAT Gateway.

### Cost-Control Principle

```bash
terraform destroy
```

when you stop working, and:

```bash
terraform apply
```

when you start again.

### Actual Cost

After destroying the infrastructure, wait one day and check:

```text
Billing → Cost Explorer
```

Record the actual total cost here:

```text
Actual Cost Paid: $________
```

---

## 🗑️ 10. How to Destroy

Before destroying the project:

### 1. Take the Final Screenshots

Take all required screenshots before destroying the resources.

### 2. Empty the S3 Buckets

Both S3 buckets must be emptied, including old object versions.

The buckets are:

```text
depi-sec-app-<random-suffix>
depi-sec-logs-<random-suffix>
```

If old versions remain, Terraform destroy can fail.

### 3. Run Terraform Destroy

From the Terraform directory:

```bash
terraform destroy
```

Review the destroy plan carefully.

When prompted, type:

```text
yes
```

### 4. Verify the AWS Console

After the destroy operation, check that the project resources are no longer running.

The project specifically requires checking for:

```text
ALB
EC2
RDS
VPC Endpoints
CloudFront
```

### 5. Verify Terraform State

Run:

```bash
terraform show
```

The expected result after a successful destroy is that there is nothing left to show.

### ⚠️ Backup Vault Note

The AWS Backup Vault uses Governance Mode Vault Lock.

A locked recovery point may prevent a complete destroy until its retention period ends.

If the recovery point cannot be deleted:

- Destroy the other resources.
- Keep the backup vault.
- Record in this README when the retention period ends.

This limitation should be documented honestly rather than bypassed.

---

## 📚 11. What I Learned

1. I learned how to build an AWS environment using Terraform instead of creating resources manually.
2. I learned the difference between public and private subnets.
3. I learned how route tables determine whether a subnet is public or private.
4. I learned how Security Groups can control communication between application tiers.
5. I learned why Security Group references are useful instead of using fixed CIDR ranges for application tiers.
6. I learned the difference between stateful Security Groups and stateless Network ACLs.
7. I learned how VPC endpoints allow private resources to access AWS services without an Internet route.
8. I learned how to access private EC2 instances using Session Manager without an SSH key or public IP.
9. I learned how to protect S3, RDS, EBS, and EFS using encryption and access controls.
10. I learned how CloudFront and an Application Load Balancer can provide a controlled path to private application servers.
11. I learned how CloudTrail records AWS API activity.
12. I learned how VPC Flow Logs provide network traffic metadata.
13. I learned how CloudWatch and SNS can be used for monitoring and alerting.
14. I learned how EventBridge and Lambda can automatically remediate an insecure Security Group rule.
15. I learned how VPC Peering provides private connectivity between two VPCs.
16. I learned how AWS Backup and Vault Lock can protect recovery points from early deletion.
17. I learned why Terraform state must never be committed to GitHub.
18. I learned that infrastructure as code makes it possible to destroy and recreate the environment consistently.

---

## ⚠️ 12. Known Limitations

- The CloudFront origin uses HTTP only as required by the project. In a production environment, the origin should use HTTPS.
- The CloudFront origin verification header is one security layer and should not be treated as a password.
- Terraform state is stored locally in this learning project. In a real environment, the state should be stored in a protected remote backend.
- The RDS password still exists in `terraform.tfstate`, which is why the state file must never be committed to GitHub.
- The project uses a single AWS Region: `us-east-1`.
- The Tools VPC contains one monitoring server and one private subnet.
- VPC Peering is not transitive.
- The project uses AWS Backup Vault Lock in Governance Mode because this is a learning account. Compliance Mode is not used.
- The Application Load Balancer and VPC interface endpoints generate costs, so the environment should be destroyed when it is not being used.
- The project is designed as a learning environment and can be improved further for a production deployment.