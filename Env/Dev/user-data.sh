#!/bin/bash
# DEV Environment EC2 User Data Script
# Install updates and monitoring

# Update OS
yum update -y

# Install CloudWatch Agent
yum install -y amazon-cloudwatch-agent

# Configure CloudWatch Agent (JSON config can be in S3 or local)
cat <<EOT >> /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/messages",
            "log_group_name": "/${PROJECT_NAME}/dev/messages",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          }
        ]
      }
    }
  }
}
EOT

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

# Example App Startup
echo "Hello from DEV $(hostname)" > /var/www/html/index.html
systemctl start httpd
systemctl enable httpd