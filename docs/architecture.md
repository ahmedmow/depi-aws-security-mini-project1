# Network and Platform Architecture

## 1. High-Level Architecture Overview

This platform is built following AWS Security Best Practices and the Defense-in-Depth model. The primary goal is to isolate application components within private subnets while delivering a secure web application to external users.

The architecture is deployed across two Availability Zones (us-east-1a and us-east-1b) inside the main application VPC (depi-sec-app-vpc). All external access to internal components passes strictly through perimeter security controls. In addition, a separate management VPC (depi-sec-tools-vpc) allows security teams to access the internal network privately using VPC Peering.
 [ Internet Users ]
│
▼
[ CloudFront ] ── (Caching & HTTPS Front Door)
│
│ (X-Origin-Verify Secret Header)
▼
[ Application Load Balancer ] ── (Public Subnets: depi-sec-public-a & b)
│
┌─────┴─────────────────────────┐
▼                               ▼
[ EC2 App Server (AZ-a) ]    [ EC2 App Server (AZ-b) ] ── (Private Subnets: depi-sec-private-a & b)
│                               │
├───────────────────────────────┼───────────────────────────────┐
▼                               ▼                               ▼
[ RDS MySQL Database ]       [ Shared EFS Storage ]         [ VPC Endpoints ]
(Private Subnets)            (Private Subnets)              (SSM, S3 Gateway, EC2 Messages)


## 2. Subnet and Routing Specification

The network is split into separate public and private subnets across two Availability Zones to maintain platform availability.

1. depi-sec-public-a
   - CIDR Block: 10.0.1.0/24
   - Availability Zone: us-east-1a
   - Type: Public Subnet
   - Routing: Direct route (0.0.0.0/0) to the Internet Gateway (IGW).
   - Resource Allocation: Public Application Load Balancer (ALB) only.

2. depi-sec-public-b
   - CIDR Block: 10.0.2.0/24
   - Availability Zone: us-east-1b
   - Type: Public Subnet
   - Routing: Direct route (0.0.0.0/0) to the Internet Gateway (IGW).
   - Resource Allocation: Public Application Load Balancer (ALB) only.

3. depi-sec-private-a
   - CIDR Block: 10.0.11.0/24
   - Availability Zone: us-east-1a
   - Type: Private Subnet
   - Routing: Local VPC routing (10.0.0.0/16) and S3 Gateway Endpoint route. No route to the Internet Gateway or NAT Gateway.
   - Resource Allocation: EC2 Application Instance, RDS Database, EFS Storage, and VPC Interface Endpoints.

4. depi-sec-private-b
   - CIDR Block: 10.0.12.0/24
   - Availability Zone: us-east-1b
   - Type: Private Subnet
   - Routing: Local VPC routing (10.0.0.0/16) and S3 Gateway Endpoint route. No route to the Internet Gateway or NAT Gateway.
   - Resource Allocation: EC2 Application Instance, RDS Database, EFS Storage, and VPC Interface Endpoints.

5. depi-sec-tools-a
   - CIDR Block: 10.1.1.0/24
   - Availability Zone: us-east-1a
   - Type: Private Tools Subnet
   - Routing: Route to app-vpc (10.0.0.0/16) through the VPC Peering Connection.
   - Resource Allocation: Isolated Monitoring and Management EC2 Instance.

---

## 3. Route Tables Summary

Public Route Table (depi-sec-public-rt)
- Destination: 10.0.0.0/16 -> Target: local
- Destination: 0.0.0.0/0 -> Target: Internet Gateway (igw)
- Subnets: depi-sec-public-a, depi-sec-public-b

Private Route Table (depi-sec-private-rt)
- Destination: 10.0.0.0/16 -> Target: local
- Destination: S3 Prefix List -> Target: S3 Gateway Endpoint (vpce)
- Destination: 10.1.0.0/16 -> Target: VPC Peering Connection (pcx)
- Subnets: depi-sec-private-a, depi-sec-private-b

Tools Route Table (depi-sec-tools-rt)
- Destination: 10.1.0.0/16 -> Target: local
- Destination: 10.0.0.0/16 -> Target: VPC Peering Connection (pcx)
- Subnets: depi-sec-tools-a

---

## 4. How Traffic Travels Through the System

### User Access Path
1. The user connects to the website using the CloudFront HTTPS URL.
2. CloudFront processes the request and sends it to the Application Load Balancer (ALB) with a secret header (X-Origin-Verify).
3. The ALB checks the header. If correct, it forwards the traffic to the EC2 instances in the private subnets.
4. If a user tries to access the ALB directly without CloudFront, the ALB blocks the request with a 403 Forbidden error.
5. The EC2 web servers process the request and read or write data to the private RDS MySQL database and EFS storage.

### Administrative Access Path
1. Administrators connect to the EC2 instances using AWS Systems Manager (SSM) Session Manager.
2. Traffic stays completely inside the AWS network using interface VPC Endpoints.
3. No SSH keys are used, and port 22 is completely closed.

---

## 5. Security Design Decisions

- Why EC2 and RDS are in Private Subnets: Keeping servers and databases in private subnets protects them from direct attacks from the internet.
- Why No Public IPs or SSH Keys: Removing public IPs prevents internet scanners from reaching the servers. Removing SSH keys eliminates the risk of lost or stolen private keys.
- Why VPC Endpoints are Used: VPC Endpoints allow private instances to communicate with AWS services (like Systems Manager and S3) without using an Internet Gateway or NAT Gateway.
- Why Two Availability Zones are Used: Deploying resources across us-east-1a and us-east-1b ensures the application stays online even if one Availability Zone has an outage.