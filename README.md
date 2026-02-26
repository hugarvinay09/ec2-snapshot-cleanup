AWS EC2 Snapshot and Instance Cleanup Infrastructure

Last Updated: February 26, 2026

================================================================================

1. INTRODUCTION

This repository contains production-grade Infrastructure as Code built with
Terraform to automate the cleanup and management of aged EC2 instances and
snapshots across your AWS environment. The solution is designed to reduce
storage costs, maintain compliance, and improve infrastructure hygiene by
identifying and removing resources that exceed your organization's retention
policies.

The platform includes:

- Secure multi-availability zone VPC with public and private subnets
- EC2 instance orchestration with security group controls
- Lambda-based automated cleanup functions
- CloudWatch monitoring and alerting mechanisms
- SNS notifications for operational awareness
- EventBridge scheduling for time-based execution
- IAM roles and policies following principle of least privilege
- CloudWatch Logs for complete audit trails
- Remote state management via S3 with DynamoDB locking
- GitHub OIDC integration for credential-free CI/CD deployments

This infrastructure operates in a completely automated, event-driven manner
while maintaining strict security controls and comprehensive logging of all
operations.

================================================================================

2. ARCHITECTURE AND DESIGN

System Overview

The infrastructure follows a layered approach with clear separation between
public and private network zones. Internet traffic enters through an Internet
Gateway and is routed to public subnets where it can reach NAT Gateways. These
NAT Gateways provide secure outbound-only access for resources in private
subnets, ensuring that Lambda functions and compute resources are not directly
exposed to the internet.

Network Layout

CIDR Block: 10.0.0.0/16
Public Subnets: Deployed across multiple availability zones
Private Subnets: Isolated from public internet access
NAT Gateways: Provides secure outbound connectivity
Internet Gateway: Single entry point for inbound traffic

Lambda Execution Context

The Lambda function for EC2 cleanup executes within the VPC infrastructure,
allowing it to interact with EC2 resources using VPC endpoints. The function
is assigned to private subnets and protected by a security group that permits
only necessary outbound traffic and restricts all inbound access.

Scheduling and Orchestration

CloudWatch Events (EventBridge) triggers the Lambda function on a configurable
schedule, typically executed daily. The schedule is defined via cron or rate
expressions and can be modified without redeploying the Lambda code.

Notification and Monitoring

All actions performed by the Lambda function are logged to CloudWatch Logs with
detailed timestamps and resource identifiers. Critical events trigger SNS
notifications sent to configured email addresses or other endpoints, providing
real-time awareness of cleanup operations.

State Management

Terraform state is stored remotely in an S3 bucket with server-side encryption
and versioning enabled. DynamoDB provides state locking to prevent concurrent
modifications and ensure infrastructure consistency across multiple deployments.

================================================================================

3. PREREQUISITES

Before deploying this infrastructure, ensure the following prerequisites are
met:

AWS Account Requirements

- AWS account with administrative or sufficient permissions
- Authenticated AWS credentials configured locally or via IAM roles
- S3 bucket for Terraform remote state (created separately)
- DynamoDB table for state locking with partition key "LockID"

Tooling Requirements

- Terraform version 1.0 or higher
- Python 3.11 runtime environment
- boto3 AWS SDK for Python (packaged with Lambda runtime)
- Git for version control
- PowerShell or Bash shell environment

AWS Permissions

The deployment requires IAM permissions to create:

- VPC and networking components (subnets, route tables, IGW, NAT)
- EC2 security groups and network interfaces
- IAM roles and inline policies
- Lambda functions and execution roles
- CloudWatch Event Rules and Log Groups
- SNS topics and subscriptions
- CloudWatch Alarms

For details on specific permissions needed, refer to the IAM policy documents
included in this repository.

Region Configuration

The infrastructure is designed to be region-agnostic. Specify your target AWS
region in the variables.tf file or via command-line arguments during
deployment. Multi-region deployments can be achieved by applying the same
configuration to different regions.

================================================================================

4. DEPLOYMENT GUIDE

Step 1: Environment Setup

Create a new directory for your deployment:

mkdir ec2-snapshot-cleanup
cd ec2-snapshot-cleanup

Clone or download all Terraform configuration files into this directory. The
repository should contain:

- main.tf (VPC, subnets, route tables)
- lambda.tf (Lambda function definitions)
- eventbridge.tf (scheduling configuration)
- iam.tf (IAM roles and policies)
- cloudwatch.tf (monitoring setup)
- sns.tf (notification topics)
- variables.tf (input variables)
- outputs.tf (exported values)
- provider.tf (AWS provider configuration)
- networking.tf (security groups and network ACLs)

Verify all files are present before proceeding.

Step 2: Configure Variables

Open variables.tf and customize all variables according to your environment:

region - AWS region where resources will be deployed [default: us-east-1]
environment - Deployment environment identifier [dev/qa/prod]
vpc_cidr - Primary CIDR block for VPC [default: 10.0.0.0/16]
project_name - Name used for resource tagging and identification
notification_email - Email address for SNS notifications
cleanup_schedule_expression - Cron or rate expression for Lambda execution

Example values:

region                        = "us-east-1"
environment                   = "prod"
vpc_cidr                      = "10.0.0.0/16"
public_subnet_cidrs          = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs         = ["10.0.10.0/24", "10.0.11.0/24"]
project_name                 = "snapshot-cleanup"
notification_email           = "pennymac-ops@pennymac.com"
cleanup_schedule_expression  = "cron(0 2 * * ? *)"

The schedule expression "cron(0 2 * * ? *)" represents 2 AM UTC daily.

Step 3: Configure AWS Provider

Open provider.tf and ensure the AWS provider is correctly configured:

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "ec2-cleanup/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

provider "aws" {
  region = var.region
}

Replace your-terraform-state-bucket with your actual S3 bucket name.

Step 4: Initialize Terraform

Initialize the Terraform working directory:

terraform init

This command downloads the AWS provider plugin and initializes the backend
connection. If you encounter backend errors, verify the S3 bucket and DynamoDB
table exist and are accessible.

Step 5: Validate Configuration

Validate all Terraform files for syntax errors:

terraform validate

Output should show "Success! The configuration is valid."

Step 6: Review Planned Changes

Generate and review an execution plan:

terraform plan -out=tfplan

This displays all resources that will be created, modified, or deleted. Review
carefully to ensure no unexpected changes. Save the plan to a file for
reference and auditability.

Step 7: Apply Infrastructure

Deploy the infrastructure:

terraform apply tfplan

Terraform will create all resources defined in the configuration. This process
typically takes 5-10 minutes. Upon completion, Terraform outputs resource IDs,
DNS names, and other important information.

Step 8: Verify Deployment

After apply completes successfully, verify resources were created:

- Navigate to AWS Console -> VPC to confirm VPC existence
- Check EC2 -> Security Groups for cleanup-related groups
- View Lambda functions for the ec2-cleanup function
- Verify EventBridge rules exist and are enabled
- Check SNS topics for notification subscriptions

Step 9: Configure SNS Email Subscription

Navigate to SNS in AWS Console:

- Find the topic named "{project-name}-{environment}-ec2-cleanup-topic"
- Click Create Subscription
- Protocol: Email
- Endpoint: your email address
- Confirm subscription by clicking link in verification email

================================================================================

5. EC2 INSTANCE AND SNAPSHOT CLEANUP PROCESS

Retention Policy and Deletion Criteria

The cleanup function enforces a 365-day retention policy for all resources
tracking age from their creation date. This threshold ensures that:

- Development and testing resources don't accumulate indefinitely
- Storage costs remain predictable and optimized
- Compliance requirements for data retention are met
- Infrastructure remains uncluttered and performant

Age Calculation

Age is calculated as the difference between current timestamp (UTC) and the
resource creation timestamp. The timestamp comparison uses timezone-aware
datetime objects to ensure consistency across regions.

RETENTION_DAYS = 365
Current_Age = (CurrentTime - CreationTime).days
Target_for_Deletion = (Current_Age > RETENTION_DAYS)

Instance Cleanup Logic

The Lambda function identifies EC2 instances for cleanup through the following
process:

1. Query Phase

The function uses Boto3 pagination to query all EC2 instances in the account.
Pagination prevents timeout issues when accounts contain hundreds or thousands
of instances.

instance_paginator = ec2.get_paginator("describe_instances")
instance_pages = instance_paginator.paginate(
    PaginationConfig={"PageSize": 50}
)

Each page contains up to 50 instances, processed sequentially.

2. State Filtering

Only instances in "running" or "stopped" states are evaluated for deletion.
Instances in transitional states like "pending", "stopping", "terminated", or
"terminating" are skipped to avoid interference with ongoing operations.

if state in ["running", "stopped"]:
    age_days = (datetime.now(timezone.utc) - launch_time).days

3. Age Calculation

Launch time is extracted from instance metadata and compared to current UTC
time. The difference in days determines if the instance exceeds the retention
threshold.

4. Termination

Instances exceeding 365 days are marked for termination. The actual termination
API call is protected by a dry-run mode flag, allowing operators to verify
deletion targets before executing.

if age_days > RETENTION_DAYS:
    if not DRY_RUN:
        ec2.terminate_instances(InstanceIds=[instance_id])

5. Logging

Each instance evaluation is logged with its ID, current state, age, and
termination decision. This provides complete audit trails for compliance and
troubleshooting.

Snapshot Cleanup Logic

Similar to instances, the function performs comprehensive snapshot analysis:

1. Snapshot Discovery

snapshot_paginator = ec2.get_paginator("describe_snapshots")
snapshot_pages = snapshot_paginator.paginate(
    OwnerIds=["self"],
    PaginationConfig={"PageSize": 50}
)

The query is scoped to snapshots owned by the current account, excluding shared
or publicly available snapshots.

2. Age Calculation

Snapshot age is calculated identically to instances, comparing the start_time
attribute to current UTC time.

3. Deletion Determination

Snapshots older than 365 days are identified as candidates for deletion.
Associated snapshots (linked to deleted instances) are cleaned up automatically.

4. Safe Deletion

Before deletion, the function checks if snapshots are associated with active
volumes or images. Snapshots backing current resources are never deleted,
preventing infrastructure breakage.

5. Dry-Run Mode

All deletions respect the DRY_RUN flag. When set to True, the function logs
what would be deleted without performing actual deletion. This allows operators
to test and validate the cleanup logic before enabling live deletion.

DRY_RUN = True  # Change to False to enable actual deletion

Dry-Run Workflow

1. Deploy infrastructure with DRY_RUN enabled (default)
2. Execute cleanup function manually or wait for scheduled execution
3. Review CloudWatch Logs to identify targets for deletion
4. Verify no critical resources appear in deletion list
5. Review SNS notification email
6. Modify Lambda environment variable to set DRY_RUN = False
7. Redeploy Lambda function with live deletion enabled
8. Test with manual invocation before relying on scheduled execution

Transitioning from Dry-Run to Live Deletion

1. Open lambda_function.py and locate DRY_RUN = True
2. Change to DRY_RUN = False
3. Update the Lambda function:

   cd /path/to/repository
   zip -j lambda/ec2_cleanup.zip lambda/lambda_function.py
   aws lambda update-function-code \
     --function-name snapshot-cleanup-prod-ec2-cleanup \
     --zip-file fileb://lambda/ec2_cleanup.zip

4. Verify update in AWS Console or via CLI:

   aws lambda get-function-configuration \
     --function-name snapshot-cleanup-prod-ec2-cleanup

5. Monitor execution via CloudWatch Logs after next scheduled run

Emergency Snapshot Recovery

If accidental deletion occurs, AWS does not provide direct recovery for deleted
snapshots. However, instance volumes are still recoverable if instances remain
in terminated state (not yet purged). Instances can be recovered within a
configurable retention period using AWS Backup integration or by stopping
instead of terminating instances.

To prevent accidental deletion, consider implementing these measures:

- Maintain pre-cleanup snapshots using AWS Backup
- Tag critical resources with a "no-cleanup" tag and filter in Lambda
- Enable AWS Config rules to detect unauthorized deletion attempts
- Require manual approval before enabling live deletion mode

Filtering by Tags

The Lambda function can be modified to respect resource tags:

CRITICAL_TAG = "no-cleanup"

for instance in instances:
    if CRITICAL_TAG in instance.get("Tags", []):
        logger.info(f"Skipping tagged instance: {instance_id}")
        continue

Add this logic to prevent accidental deletion of protected resources.

================================================================================

6. MONITORING AND OPERATIONAL HEALTH

CloudWatch Logs Monitoring

All Lambda function execution is logged to CloudWatch Logs with the log group
pattern:

/aws/lambda/{project-name}-{environment}-ec2-cleanup

Logs include:

- Function start and completion timestamps
- Individual resource evaluation decisions
- Age calculations for each resource
- Deletion confirmations or dry-run deletions
- Error messages with full exception details
- Summary statistics at completion

Viewing Logs

AWS Console: CloudWatch -> Log Groups -> Select cleanup log group
Command Line:

aws logs tail /aws/lambda/snapshot-cleanup-prod-ec2-cleanup --follow

Logs retention is configured to 14 days by default. Extend retention for
compliance requirements by modifying log_retention_days in variables.tf.

CloudWatch Metrics

Standard Lambda metrics are automatically collected:

- Invocations: Total number of function executions
- Duration: Execution time in milliseconds
- Errors: Number of failed executions
- Throttles: Instances where Lambda rejected invocation due to concurrency
- ConcurrentExecutions: Concurrent function instances running

Monitor these metrics through AWS Console or create custom dashboards:

aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=snapshot-cleanup-prod-ec2-cleanup \
  --start-time 2026-02-20T00:00:00Z \
  --end-time 2026-02-27T00:00:00Z \
  --period 86400 \
  --statistics Sum

SNS Notifications

Cleanup execution summaries are sent via SNS email notifications containing:

- Execution timestamp
- Total instances evaluated
- Total instances terminated
- Total snapshots evaluated
- Total snapshots deleted
- Error messages if applicable
- Dry-run status indicator

Subscribe to notifications by confirming SNS email subscription. Add additional
subscribers by creating subscriptions to the SNS topic:

aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:123456789012:snapshot-cleanup-prod-ec2-cleanup-topic \
  --protocol email \
  --notification-endpoint pennymac-ops-team@pennymac.com

CloudWatch Alarms

Alarms monitor Lambda execution health and trigger when errors occur:

LambdaErrorAlarm - Triggers when error rate exceeds threshold
LambdaDurationAlarm - Triggers when execution time exceeds 280 seconds
LambdaThrottleAlarm - Triggers when Lambda is throttled

Alarm actions send SNS notifications to operations email lists. Custom alarms
can be created to monitor specific metrics:

aws cloudwatch put-metric-alarm \
  --alarm-name snapshot-cleanup-prod-high-error-rate \
  --alarm-description "Alert when cleanup function error rate is high" \
  --metric-name Errors \
  --namespace AWS/Lambda \
  --statistic Sum \
  --period 300 \
  --threshold 5 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 1

EventBridge Execution History

EventBridge maintains a complete history of invocations to the Lambda function.
Review execution history in AWS Console:

AWS Console: EventBridge -> Rules -> Select cleanup rule -> View invocations

Execution history shows:

- Invocation timestamp
- Lambda function response (success/failure)
- Error messages if applicable
- Dead letter queue status if configured

================================================================================

7. SECURITY CONSIDERATIONS AND BEST PRACTICES

IAM Permissions - Principle of Least Privilege

Lambda execution role includes only permissions required for essential
operations:

- ec2:DescribeInstances
- ec2:DescribeSnapshots
- ec2:TerminateInstances
- ec2:DeleteSnapshot
- sns:Publish
- logs:CreateLogGroup
- logs:CreateLogStream
- logs:PutLogEvents

This minimalist approach prevents the function from modifying other resource
types or accessing unrelated AWS services. If Lambda requires additional
permissions in the future, add them explicitly rather than using wildcard
permissions.

Network Isolation

Lambda executes within the private VPC subnet, isolated from direct internet
access. Outbound internet connectivity is provided through a NAT Gateway,
allowing API calls to AWS services while preventing inbound access from the
internet. This architecture ensures that compromised Lambda credentials cannot
be exploited for direct unauthorized access.

Encryption at Rest and in Transit

- Terraform state stored in S3 with server-side encryption enabled
- All APIs communicate over HTTPS (TLS 1.2 minimum)
- CloudWatch Logs are encrypted at rest by default
- SNS messages encrypted in transit

Audit Logging and Compliance

Complete audit trails are maintained through:

- CloudWatch Logs capturing all Lambda operations
- CloudTrail logging all AWS API calls made by cleanup function
- SNS notifications providing real-time alerts to operations
- Terraform state versioning enabling infrastructure rollback

Review CloudTrail logs:

aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=ResourceName,AttributeValue=snapshot-cleanup-prod-ec2-cleanup \
  --max-results 50

Tag-Based Deletion Prevention

Implement tag-based exemptions to prevent deletion of critical resources:

NO_CLEANUP_TAG = "protected"

for snapshot in snapshots:
    tags = {tag["Key"]: tag["Value"] for tag in snapshot.get("Tags", [])}
    if tags.get(NO_CLEANUP_TAG) == "true":
        logger.info(f"Skipping protected snapshot: {snapshot_id}")
        continue

Tag all critical resources with this tag, ensuring they are never deleted by
the cleanup function.

Notification Email Security

SNS email notifications use standard email transmission and may be intercepted
in transit. For sensitive environments, consider integrating with:

- Slack or Teams webhooks for instant messaging alerts
- PagerDuty for on-call escalation
- Enterprise logging systems like Splunk or DataDog

Disable Live Deletion During Testing

Always begin with DRY_RUN = True and thoroughly test cleanup logic before
enabling actual deletion. This prevents accidental destruction of infrastructure.

Restricted Access to Lambda Code Updates

Limit who can modify Lambda code to designated operations or infrastructure
teams. Use IAM policies to restrict:

- lambda:UpdateFunctionCode
- lambda:UpdateFunctionConfiguration

Deploy code changes through CI/CD pipelines with approval workflows rather than
allowing direct manual updates.

CloudWatch Logs Query Access

Restrict who can query CloudWatch Logs to prevent unauthorized review of:

- Resource inventory (discovered instances and snapshots)
- Deletion decisions and timing
- Internal error details

Use IAM policies to scope logs:CloudWatch permissions to authorized users only.

Configuration Change Auditing

All Terraform-initiated changes are logged in CloudTrail. Review changes
periodically:

aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventSource,AttributeValue=ec2.amazonaws.com \
  --start-time 2026-02-20T00:00:00Z \
  --max-results 50 | jq '.Events[] | {EventTime, EventName, CloudTrailEvent}'

Backup and Disaster Recovery

While snapshots are cleaned up automatically, maintain separate backups of:

- Terraform configuration (version control)
- Lambda source code (version control)
- State files (encrypted S3 versioning)
- Critical infrastructure snapshots (AWS Backup integration)

Enable multi-version state in S3:

aws s3api put-bucket-versioning \
  --bucket your-terraform-state-bucket \
  --versioning-configuration Status=Enabled

Multi-Account Deployments

For organizations with multiple AWS accounts, deploy infrastructure in each
account with account-specific variables. Alternatively, create a central
cleanup account with cross-account permissions:

{
  "Effect": "Allow",
  "Action": [
    "ec2:DescribeInstances",
    "ec2:DescribeSnapshots",
    "ec2:TerminateInstances",
    "ec2:DeleteSnapshot"
  ],
  "Resource": "*",
  "Condition": {
    "StringEquals": {
      "sts:ExternalId": "unique-external-id"
    }
  }
}

This allows centralized cleanup while maintaining account isolation.

================================================================================

8. OPERATIONAL PROCEDURES

Manual Function Invocation

Trigger cleanup immediately without waiting for scheduled execution:

aws lambda invoke \
  --function-name snapshot-cleanup-prod-ec2-cleanup \
  --log-type Tail \
  response.json

Review response.json for execution output.

Viewing Execution Details

Get complete details about the invocation:

aws lambda get-function \
  --function-name snapshot-cleanup-prod-ec2-cleanup

Check Lambda logs:

aws logs tail /aws/lambda/snapshot-cleanup-prod-ec2-cleanup --follow

Modifying the Cleanup Schedule

Edit the EventBridge rule to change execution frequency:

aws events put-rule \
  --name snapshot-cleanup-prod-ec2-cleanup-schedule \
  --schedule-expression "cron(0 3 * * ? *)" \
  --state ENABLED

This changes the execution to 3 AM UTC daily. Format follows AWS schedule
expressions documentation.

Temporarily Disabling Cleanup

Disable the EventBridge rule to prevent automatic execution:

aws events disable-rule \
  --name snapshot-cleanup-prod-ec2-cleanup-schedule

Re-enable when ready:

aws events enable-rule \
  --name snapshot-cleanup-prod-ec2-cleanup-schedule

Updating Retention Policy

Modify the RETENTION_DAYS variable in lambda_function.py:

RETENTION_DAYS = 180  # Changed from 365

Redeploy the function:

cd lambda
zip -j ec2_cleanup.zip lambda_function.py
aws lambda update-function-code \
  --function-name snapshot-cleanup-prod-ec2-cleanup \
  --zip-file fileb://ec2_cleanup.zip

Verify execution:

aws lambda invoke \
  --function-name snapshot-cleanup-prod-ec2-cleanup \
  --log-type Tail \
  response.json

Testing Specific Scenarios

Create test instances with specific launch times to verify cleanup logic:

aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t2.micro \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=test-cleanup-target}]'

Note the instance ID and then manually invoke the cleanup function to test
behavior.

Viewing Cost Impact

Cleanup operations reduce storage costs by removing aged snapshots. Track
savings:

aws ce get-cost-and-usage \
  --time-period Start=2026-02-20,End=2026-02-27 \
  --granularity DAILY \
  --metrics BlendedCost \
  --filter file://ec2-filter.json

Create ec2-filter.json:

{
  "Dimensions": {
    "Key": "SERVICE",
    "Values": ["Amazon Elastic Compute Cloud"]
  }
}

Incident Response - Unexpected Deletions

If resources are deleted unexpectedly:

1. Disable cleanup function immediately:

   aws events disable-rule \
     --name snapshot-cleanup-prod-ec2-cleanup-schedule

2. Review CloudWatch Logs to identify deleted resources:

   aws logs filter-log-events \
     --log-group-name /aws/lambda/snapshot-cleanup-prod-ec2-cleanup \
     --filter-pattern "DeleteSnapshot OR TerminateInstances"

3. Restore from AWS Backup or snapshots if available
4. Review deletion criteria in Lambda code
5. Investigate IAM permissions
6. Create new instances or snapshots as needed
7. Update retention logic if needed
8. Re-enable after remediation

================================================================================

9. TROUBLESHOOTING

Lambda Function Not Executing

Verify EventBridge rule is enabled:

aws events describe-rule \
  --name snapshot-cleanup-prod-ec2-cleanup-schedule

Output should show "State": "ENABLED"

Check Lambda permissions:

aws lambda get-policy \
  --function-name snapshot-cleanup-prod-ec2-cleanup

Should show EventBridge has InvokeFunction permission.

Verify SNS topic exists and subscriptions are active:

aws sns list-subscriptions-by-topic \
  --topic-arn arn:aws:sns:us-east-1:123456789012:snapshot-cleanup-prod-ec2-cleanup-topic

CloudWatch Logs Show No Activity

Verify Lambda has CloudWatch Logs permissions:

aws iam get-role-policy \
  --role-name snapshot-cleanup-prod-lambda-role \
  --policy-name snapshot-cleanup-prod-lambda-policy

Policy must include:

"logs:CreateLogGroup",
"logs:CreateLogStream",
"logs:PutLogEvents"

Check log group exists:

aws logs describe-log-groups \
  --log-group-name-prefix /aws/lambda/snapshot-cleanup-prod

Create if missing:

aws logs create-log-group \
  --log-group-name /aws/lambda/snapshot-cleanup-prod-ec2-cleanup

Lambda Execution Timeout

If Lambda function times out after 300 seconds, increase timeout:

aws lambda update-function-configuration \
  --function-name snapshot-cleanup-prod-ec2-cleanup \
  --timeout 600

Also increase memory allocation to improve execution speed:

aws lambda update-function-configuration \
  --function-name snapshot-cleanup-prod-ec2-cleanup \
  --memory-size 512

SNS Notifications Not Received

Verify subscription is confirmed. Check AWS Console -> SNS -> Subscriptions and
look for "Confirmed" status.

If subscription pending, confirm via email link from SNS.

Resend confirmation:

aws sns set-subscription-attributes \
  --subscription-arn arn:aws:sns:us-east-1:123456789012:snapshot-cleanup-prod-ec2-cleanup-topic:12345678-1234-1234-1234-123456789012 \
  --attribute-name SubscriptionRoleArn \
  --attribute-value arn:aws:iam::123456789012:role/SNSSuccessFeedbackRole

Deployment Failures

Terraform init fails: Verify S3 bucket and DynamoDB table are accessible and in
the correct region specified in provider.tf

Terraform plan shows unexpected changes: Run terraform refresh to update state
from AWS resources

Terraform apply fails: Check IAM permissions for all resource types being
created. Review specific error messages for guidance.

State Lock Issues

If state locked due to previous crash:

aws dynamodb delete-item \
  --table-name terraform-locks \
  --key '{"LockID": {"S": "ec2-cleanup/terraform.tfstate"}}'

After resolving the lock, redeploy:

terraform apply -auto-approve

Lambda Execution Errors

Review error logs:

aws logs filter-log-events \
  --log-group-name /aws/lambda/snapshot-cleanup-prod-ec2-cleanup \
  --filter-pattern "Error"

Common errors and solutions:

- "User: arn:aws:iam not authorized to perform ec2:DescribeSnapshots": Lambda
  IAM role lacks required permissions. Add missing EC2 actions to role.

- "InvalidSnapshot.NotFound": Attempting to delete already-deleted snapshot.
  Add error handling to catch and continue.

- "InsufficientInstanceCapacity": Not enough capacity to provision instances.
  Wait and retry or select different instance type.

Resource Not Found Errors

If Terraform reports resources missing or destroyed externally:

terraform refresh

Terraform state is updated to reflect current infrastructure state. Plan and
apply again if needed.

For complete restoration:

terraform destroy
terraform apply

This recreates all resources from scratch.

================================================================================

10. MAINTENANCE AND UPDATES

Terraform Version Updates

Review Terraform Changelog before updating. Test updates in dev environment:

terraform -version

Update provider version in provider.tf:

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.5"
    }
  }
}

Reinitialize and test:

terraform init
terraform plan

Python Lambda Runtime Updates

AWS deprecates Python versions periodically. Monitor AWS Lambda documentation
for deprecation dates. Update Lambda runtime:

aws lambda update-function-configuration \
  --function-name snapshot-cleanup-prod-ec2-cleanup \
  --runtime python3.12

Test thoroughly before production deployment.

Boto3 Library Updates

Lambda runtime includes boto3 by default. For custom dependencies, create
Lambda layer:

mkdir python
cd python
pip install boto3==1.28.0 -t .
cd ..
zip -r boto3-layer.zip python

Deploy layer:

aws lambda publish-layer-version \
  --layer-name snapshot-cleanup-boto3-layer \
  --zip-file fileb://boto3-layer.zip \
  --compatible-runtimes python3.11

Attach to Lambda:

aws lambda update-function-configuration \
  --function-name snapshot-cleanup-prod-ec2-cleanup \
  --layers arn:aws:lambda:us-east-1:123456789012:layer:snapshot-cleanup-boto3-layer:1

Retention Policy Adjustments

Review retention policy annually or after major infrastructure changes:

- Reduce retention for aggressive cost cutting
- Increase retention for long-running workloads
- Create exception lists for critical resources

Document policy decisions:

RETENTION_DAYS = 365  # Reviewed Feb 2026, industry standard maintained
EXCEPTIONS = ["critical-db-snapshot", "production-backup"]

Log Policy Changes

Create audit log entry when policy changes:

echo "RETENTION_DAYS=365 - Updated Feb 26, 2026 by OPS team" >> POLICY_LOG.txt

Resource Tagging Strategy

Develop tagging strategy to organize and manage resources:

Tags to implement:

- Environment: prod/qa/dev
- Owner: team or person responsible
- CostCenter: billing allocation
- Retention: custom retention policy
- BackupRequired: true/false
- Compliance: regulatory requirements

Apply tags uniformly across all resources for consistency.

================================================================================

11. INFRASTRUCTURE COMPONENTS

VPC Configuration

Main VPC provides isolated network environment with 10.0.0.0/16 CIDR block
supporting up to 65,536 IP addresses across all subnets.

Public subnets receive direct internet routing via Internet Gateway. NAT
Gateways in public subnets provide secure outbound-only access for private
resources.

Internet Gateway

Single Internet Gateway attached to VPC enables ingress and egress traffic to
the public internet. All public subnet traffic routes through IGW.

NAT Gateway

Located in each public subnet, NAT Gateway provides network address translation
for private subnet resources. Outbound traffic from private resources appears to
originate from NAT Gateway public IP, masking internal addresses.

Security Groups

- Public security group: Allows SSH (22) and HTTPS (443) inbound
- Lambda security group: Restricts all inbound, allows all outbound
- Database security group (if applicable): Restricted to Lambda and private IPs

IAM Roles and Policies

Lambda Execution Role: Allows Lambda service to assume role
Lambda Inline Policy: Grants specific EC2, SNS, and CloudWatch Logs permissions

EventBridge Rule

Trigger configuration:

- Rule type: Schedule
- Schedule pattern: "cron(0 2 * * ? *)"
- Targets: Lambda function
- Retry policy: Maximum 2 retries with 60 second intervals

Lambda Function Configuration

- Runtime: Python 3.11
- Handler: lambda_function.lambda_handler
- Timeout: 300 seconds
- Memory: 256 MB
- Ephemeral storage: 512 MB (default)
- VPC configuration: Private subnets, Lambda security group
- Environment variables: SNS_TOPIC_ARN, DRY_RUN=True

SNS Topic

Topic name: {project-name}-{environment}-ec2-cleanup-topic
Encryption: Enabled via AWS KMS
Retention: 345,600 seconds (4 days)

CloudWatch Logs

Log group: /aws/lambda/{project-name}-{environment}-ec2-cleanup
Retention: 14 days (configurable)
Format: JSON for structured analysis

================================================================================

12. COST CONSIDERATIONS

Pricing Components

VPC, Security Groups, Route Tables: No charge
NAT Gateway: $45.00 per month per gateway + data transfer costs
Internet Gateway: No charge
Lambda: $0.20 per million requests + $0.0000166667 per GB-second
CloudWatch Logs: $0.50 per GB ingested + $0.03 per GB stored
SNS: $0.50 per million email notifications
EventBridge: $1.00 per million events published

Estimated Monthly Cost (assuming 2 NAT Gateways, 1000 Lambda invocations daily)

NAT Gateways: 90.00
Lambda: 0.10
CloudWatch Logs: 1.50
SNS: 0.00 (first 1000 free)
EventBridge: 0.03
Total: ~91.63 per month

Cost Optimization

- Use CloudWatch Events (now EventBridge) instead of API calls
- Consolidate Lambda functions to reduce cold start overhead
- Archive old logs to S3 for long-term retention
- Right-size Lambda memory allocation based on usage patterns
- Clean up aged snapshots aggressively to reduce storage

Reserved Capacity

Consider AWS Savings Plans for predictable long-term costs:

- Compute Savings Plans: 30 percent discount on Lambda
- Regional Reserved Capacity: Discounts for consistent usage

Cost Tracking

Enable Cost Allocation Tags on all resources:

aws ec2 create-tags \
  --resources $(aws ec2 describe-instances --query 'Reservations[0].Instances[0].InstanceId' --output text) \
  --tags Key=CostCenter,Value=Operations

Query costs by tag:

aws ce get-cost-and-usage \
  --time-period Start=2026-02-20,End=2026-02-27 \
  --granularity DAILY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=TAG \
  --filter file://tag-filter.json

================================================================================

This documentation represents a complete operational guide for the EC2 snapshot
and instance cleanup infrastructure. All procedures have been tested in
production environments and follow AWS best practices and security guidelines.

For questions or issues, review CloudWatch Logs for detailed execution traces,
consult AWS official documentation, or contact your infrastructure team.

Version: 1.0
Last Reviewed: February 26, 2026
