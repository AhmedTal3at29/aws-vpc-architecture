# AWS VPC Architecture - Public & Private EC2 Setup

A hands-on implementation of a secure AWS network architecture with public and private subnets across two Availability Zones.

---

## 📐 Architecture Overview

```
Internet
    │
   IGW (Internet Gateway)
    │
┌───────────────────────────────────────────┐
│                   VPC (10.0.0.0/16)       │
│                                           │
│  ┌─────────────────┐  ┌────────────────┐  │
│  │   AZ1 - Public  │  │ AZ2 - Private  │  │
│  │  10.0.1.0/24    │  │  10.0.2.0/24   │  │
│  │                 │  │                │  │
│  │  ┌──────────┐   │  │  ┌──────────┐  │  │
│  │  │ EC2      │   │  │  │ EC2      │  │  │
│  │  │10.0.1.121│   │  │  │10.0.2.246│  │  │
│  │  └──────────┘   │  │  └──────────┘  │  │
│  │       │         │  │       ↑        │  │
│  │  ┌────┴───┐     │  │       │        │  │
│  │  │  NAT   │─────┼──┼───────┘        │  │
│  │  └────────┘     │  │                │  │
│  └─────────────────┘  └────────────────┘  │
└───────────────────────────────────────────┘
         │
     AMI Stored (S3)
```

---

## 🧩 Components

| Component | Configuration |
|---|---|
| **VPC** | CIDR: `10.0.0.0/16` |
| **Public Subnet (AZ1)** | CIDR: `10.0.1.0/24` |
| **Private Subnet (AZ2)** | CIDR: `10.0.2.0/24` |
| **Internet Gateway (IGW)** | Attached to VPC |
| **NAT Gateway** | Deployed in Public Subnet |
| **Public EC2** | Private IP: `10.0.1.121` |
| **Private EC2** | Private IP: `10.0.2.246` |
| **AMI** | Created from Public EC2, stored in S3 |

---

## 🔒 Security Groups

### Public EC2 SG
| Type | Protocol | Port | Source |
|---|---|---|---|
| SSH | TCP | 22 | My IP |
| HTTP | TCP | 80 | 0.0.0.0/0 |
| All ICMP | ICMP | All | 0.0.0.0/0 |

### Private EC2 SG
| Type | Protocol | Port | Source |
|---|---|---|---|
| SSH | TCP | 22 | public-sg |
| All ICMP | ICMP | All | public-sg |

---

## 🛣️ Route Tables

### Public Route Table
| Destination | Target |
|---|---|
| `10.0.0.0/16` | local |
| `0.0.0.0/0` | IGW |

### Private Route Table
| Destination | Target |
|---|---|
| `10.0.0.0/16` | local |
| `0.0.0.0/0` | NAT Gateway |

---

## 🚀 Setup Steps

### 1. Create VPC
```
VPC → Create VPC
- Name: my-vpc
- IPv4 CIDR: 10.0.0.0/16
```

### 2. Create Subnets
```
# Public Subnet
Name: public-subnet | AZ: us-east-1a | CIDR: 10.0.1.0/24

# Private Subnet
Name: private-subnet | AZ: us-east-1b | CIDR: 10.0.2.0/24
```

### 3. Create & Attach Internet Gateway
```
Internet Gateways → Create IGW → Attach to my-vpc
```

### 4. Create NAT Gateway
```
NAT Gateways → Create
- Subnet: public-subnet
- Allocate Elastic IP
```

### 5. Configure Route Tables
```
# Public RT: 0.0.0.0/0 → IGW → Associate public-subnet
# Private RT: 0.0.0.0/0 → NAT → Associate private-subnet
```

### 6. Launch EC2 Instances
```
# Public EC2
- Subnet: public-subnet
- Auto-assign Public IP: Enabled
- SG: public-sg

# Private EC2
- Subnet: private-subnet
- Auto-assign Public IP: Disabled
- SG: private-sg
```

### 7. Create AMI
```
EC2 → Select Public Instance → Actions → Image → Create Image
```

---

## ✅ Testing & Validation

### Connectivity Tests

```bash
# 1. From Local Machine → Public EC2 (tests IGW)
ssh -i key.pem ec2-user@<PUBLIC-EC2-IP>

# 2. From Public EC2 → Internet (tests IGW outbound)
ping 8.8.8.8
curl ifconfig.me

# 3. From Public EC2 → Private EC2 (tests VPC routing)
ping 10.0.2.246
ssh ec2-user@10.0.2.246

# 4. From Private EC2 → Internet (tests NAT Gateway)
ping 8.8.8.8
curl ifconfig.me   # Should return NAT Gateway Elastic IP
```

### Expected Results

| Test | From | Expected |
|---|---|---|
| SSH to Public EC2 | Local Machine | ✅ Connected |
| Ping 8.8.8.8 | Public EC2 | ✅ Reply |
| Ping Private EC2 (private IP) | Public EC2 | ✅ Reply |
| SSH to Private EC2 | Public EC2 | ✅ Connected |
| Ping 8.8.8.8 | Private EC2 | ✅ Reply via NAT |
| `curl ifconfig.me` | Private EC2 | ✅ Shows NAT EIP |
| SSH to Private EC2 | Local Machine | ❌ Timeout *(correct!)* |

---

## 🔑 SSH Access to Private EC2

Use **SSH Agent Forwarding** — no need to copy your PEM key to the server:

```bash
# On your local machine
eval $(ssh-agent -s)
ssh-add /path/to/key.pem

# Connect to Public EC2 with forwarding enabled
ssh -A -i /path/to/key.pem ec2-user@<PUBLIC-EC2-IP>

# From inside Public EC2, jump to Private EC2
ssh ec2-user@10.0.2.246
```

---

## 💡 Key Concepts

### IGW vs NAT Gateway
| | IGW | NAT Gateway |
|---|---|---|
| Used by | Public EC2 | Private EC2 |
| Allows inbound from Internet | ✅ | ❌ |
| Allows outbound to Internet | ✅ | ✅ |

### Important: Always Use Private IP Within VPC
> When communicating between instances **inside the VPC**, always use the **Private IP**.
> Using the Public IP from within the VPC causes **Hairpin NAT** issues and will fail.

```bash
# ❌ Wrong - from inside VPC
ping 3.230.125.153   # Public IP - will fail

# ✅ Correct - from inside VPC
ping 10.0.1.121      # Private IP - works perfectly
```

---

## 📁 Repository Structure

```
aws-vpc-architecture/
│
├── README.md          # This file
├── architecture/
│   └── diagram.png    # Architecture diagram
└── scripts/
    └── test.sh        # Connectivity test script
```

---

## 🧪 Quick Test Script

```bash
#!/bin/bash
# Run from inside Public EC2

PRIVATE_IP="10.0.2.246"

echo "=== AWS Architecture Connectivity Tests ==="

echo -e "\n[1] Internet reachability (IGW):"
ping -c 3 8.8.8.8 && echo "✅ IGW OK" || echo "❌ IGW FAIL"

echo -e "\n[2] DNS Resolution:"
ping -c 3 google.com && echo "✅ DNS OK" || echo "❌ DNS FAIL"

echo -e "\n[3] Private EC2 reachability:"
ping -c 3 $PRIVATE_IP && echo "✅ Private EC2 OK" || echo "❌ Private EC2 FAIL"

echo -e "\n[4] Private EC2 SSH port:"
nc -zv $PRIVATE_IP 22 && echo "✅ SSH Port OK" || echo "❌ SSH Port FAIL"

echo -e "\n=== Tests Complete ==="
```

---

## 📝 License

MIT License - feel free to use and modify.
