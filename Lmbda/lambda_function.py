import boto3
import logging
import os
from datetime import datetime, timezone

# -----------------------------
# Logging Configuration
# -----------------------------
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# -----------------------------
# AWS Clients
# -----------------------------
ec2 = boto3.client("ec2")
sns = boto3.client("sns")

# -----------------------------
# Configuration from Environment
# -----------------------------
RETENTION_DAYS = int(os.environ.get("RETENTION_DAYS", 365))
DRY_RUN = os.environ.get("DRY_RUN", "True").lower() == "true"
SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN")
ENVIRONMENT = os.environ.get("ENVIRONMENT", "dev")

# -----------------------------
# Lambda Handler
# -----------------------------
def lambda_handler(event, context):
    try:
        logger.info(f"Starting EC2 & Snapshot cleanup for environment: {ENVIRONMENT}")
        snapshot_results = handle_snapshots()
        instance_results = handle_instances()
        send_sns_report(snapshot_results, instance_results)
        
        return {
            "statusCode": 200,
            "body": {
                "snapshot_results": snapshot_results,
                "instance_results": instance_results,
                "dry_run": DRY_RUN
            }
        }

    except Exception as e:
        logger.exception("An error occurred during cleanup")
        raise e

# -----------------------------
# Handle Snapshots
# -----------------------------
def handle_snapshots():
    snapshot_paginator = ec2.get_paginator("describe_snapshots")
    snapshot_pages = snapshot_paginator.paginate(
        OwnerIds=["self"],
        PaginationConfig={"PageSize": 50}
    )

    deleted_snapshots = []
    total_snapshots = 0

    for page in snapshot_pages:
        for snapshot in page.get("Snapshots", []):
            total_snapshots += 1
            snapshot_id = snapshot["SnapshotId"]
            start_time = snapshot["StartTime"]
            age_days = (datetime.now(timezone.utc) - start_time).days

            logger.info(f"Snapshot {snapshot_id} | Age: {age_days} days")

            if age_days > RETENTION_DAYS:
                logger.warning(f"Snapshot {snapshot_id} older than {RETENTION_DAYS} days")
                if not DRY_RUN:
                    ec2.delete_snapshot(SnapshotId=snapshot_id)
                    logger.info(f"Deleted Snapshot: {snapshot_id}")
                deleted_snapshots.append(snapshot_id)

    logger.info(f"Total Snapshots Found: {total_snapshots}")
    logger.info(f"Snapshots Marked for Deletion: {len(deleted_snapshots)}")

    return {
        "total_snapshots": total_snapshots,
        "deleted_snapshots": deleted_snapshots
    }

# -----------------------------
# Handle EC2 Instances
# -----------------------------
def handle_instances():
    instance_paginator = ec2.get_paginator("describe_instances")
    instance_pages = instance_paginator.paginate(PaginationConfig={"PageSize": 50})

    deleted_instances = []
    total_instances = 0

    for page in instance_pages:
        for reservation in page.get("Reservations", []):
            for instance in reservation.get("Instances", []):
                total_instances += 1
                instance_id = instance["InstanceId"]
                launch_time = instance["LaunchTime"]
                state = instance["State"]["Name"]

                logger.info(f"Checking Instance {instance_id} | State: {state}")

                if state in ["running", "stopped"]:
                    age_days = (datetime.now(timezone.utc) - launch_time).days

                    if age_days > RETENTION_DAYS:
                        logger.warning(f"Instance {instance_id} is {age_days} days old")
                        if not DRY_RUN:
                            ec2.terminate_instances(InstanceIds=[instance_id])
                            logger.info(f"Terminated Instance: {instance_id}")
                        deleted_instances.append(instance_id)

    logger.info(f"Total Instances Checked: {total_instances}")
    logger.info(f"Instances Marked for Termination: {len(deleted_instances)}")

    return {
        "total_instances": total_instances,
        "deleted_instances": deleted_instances
    }

# -----------------------------
# Send SNS Report
# -----------------------------
def send_sns_report(snapshot_results, instance_results):
    if not SNS_TOPIC_ARN:
        logger.warning("SNS_TOPIC_ARN not set, skipping notification")
        return

    message = f"""
Environment: {ENVIRONMENT}

Deleted EC2 Instances:
{instance_results['deleted_instances']}

Deleted Snapshots:
{snapshot_results['deleted_snapshots']}

Dry Run Mode: {DRY_RUN}
"""

    sns.publish(
        TopicArn=SNS_TOPIC_ARN,
        Subject=f"[{ENVIRONMENT.upper()}] EC2 & Snapshot Cleanup Report",
        Message=message
    )

    logger.info("SNS notification sent successfully")