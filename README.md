# 🚀 Enterprise CI/CD Infrastructure on AWS using GitHub OIDC + Terraform

## 📌 Architecture Overview

This project provisions:

- Custom VPC
- Internet Gateway
- NAT Gateway
- Route Tables (Public & Private)
- EC2 Instance
- GitHub OIDC Authentication
- CloudWatch Log Group
- Metric Filter (detect ERROR logs)
- CloudWatch Alarm (Errors > 0)
- SNS Notification System

---

# 🔐 OIDC Authentication (GitHub → AWS)

We use OpenID Connect (OIDC) to allow GitHub Actions to authenticate securely with AWS without static credentials.

## Flow:

1. GitHub Action requests OIDC token
2. AWS validates token via IAM role trust policy
3. Temporary AWS credentials issued
4. Terraform deploys infrastructure

---

# 🌐 Networking Architecture

## VPC
- CIDR: 10.0.0.0/16

## Subnets
- Public Subnet
- Private Subnet

## Internet Gateway
Allows internet access to public subnet.

## NAT Gateway
- Deployed in Public Subnet
- Allows outbound internet from Private Subnet

## Route Tables
- Public Route Table → IGW
- Private Route Table → NAT Gateway

---

# ☁️ Observability & Monitoring

## CloudWatch Log Group

Log group:
```
/aws/ec2/app-logs
```

Stores application logs.

---

## Metric Filter

Pattern:
```
ERROR
```

This filter transforms any log line containing ERROR into a custom metric:

Namespace:
```
CICDAppMetrics
```

Metric Name:
```
ErrorCount
```

---

## CloudWatch Alarm

Condition:
```
ErrorCount > 0
```

Evaluation:
- 1 minute period
- Alarm triggers immediately

---

## SNS Notification

When alarm state = ALARM:

- SNS topic triggers
- Email notification sent
- Requires email confirmation

---

# 🛠 Deployment Steps

# Please add required secrets in secrets and varibales section inside the repositroy without forget. 

## Step 1 – Clone Repository

```bash
git clone <repo>
cd terraform
```

---

## Step 2 – Initialize

```bash
terraform init
```

---

## Step 3 – Validate

```bash
terraform validate
```

---

## Step 4 – Plan

```bash
terraform plan -var="alert_email=your@email.com"
```

---

## Step 5 – Apply

```bash
terraform apply -auto-approve -var="alert_email=your@email.com"
```

Confirm SNS email subscription.

---

# 🧪 Testing Alarm

SSH into EC2 instance.

Push error log:

```bash
echo "ERROR Application failure" >> /var/log/app.log
```

Within 60 seconds:

- Metric increments
- Alarm triggers
- Email received

---

# 📊 Production Design Considerations

✔ Use 2 NAT Gateways (HA)  
✔ Multi-AZ architecture  
✔ Add CloudWatch Dashboard  
✔ Enable Auto Scaling  
✔ Integrate with Jira for auto-ticket on alarm  
✔ Integrate with Lambda for automation  

---

# 🔄 CI/CD Integration

GitHub Actions workflow should include:

```yaml
permissions:
  id-token: write
  contents: read
```

And use:

```
aws-actions/configure-aws-credentials
```

---

# 🏁 Destroy Infrastructure

```bash
terraform destroy
```

---

# 🛡 Security Best Practices

- No static AWS access keys
- Least privilege IAM
- Encrypted SNS
- Log retention policy
- Private subnet isolation

---

# 🎯 Final Result

If:
- CI/CD pipeline fails
- Application throws ERROR
- Logs contain ERROR

Then:
- CloudWatch metric increments
- Alarm triggers immediately
- SNS sends notification
- (Optional) Jira ticket auto-created