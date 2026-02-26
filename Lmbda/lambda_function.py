import boto3
import logging
from datetime import datetime, timezone

logger = logging.getLogger()
logger.setLevel(logging.INFO)

ec2 = boto3.client("ec2")

# Configuration
RETENTION_DAYS = 365
DRY_RUN = True   # 🔴 Change to False to enable actual deletion


def lambda_handler(event, context):
    try:
        logger.info("Starting EC2 & Snapshot audit process")

        ############################################
        # 1️⃣ Handle Snapshots (Paginated)
        ############################################

        snapshot_paginator = ec2.get_paginator("describe_snapshots")

        snapshot_pages = snapshot_paginator.paginate(
            OwnerIds=["self"],
            PaginationConfig={"PageSize": 50}
        )

        total_snapshots = 0

        for page in snapshot_pages:
            for snapshot in page.get("Snapshots", []):
                total_snapshots += 1
                logger.info(f"Snapshot found: {snapshot['SnapshotId']}")

        logger.info(f"Total Snapshots Found: {total_snapshots}")

        ############################################
        # 2️⃣ Handle EC2 Instances (Paginated)
        ############################################

        instance_paginator = ec2.get_paginator("describe_instances")

        instance_pages = instance_paginator.paginate(
            PaginationConfig={"PageSize": 50}
        )

        terminated_instances = []
        total_instances = 0

        for page in instance_pages:
            for reservation in page.get("Reservations", []):
                for instance in reservation.get("Instances", []):

                    total_instances += 1

                    instance_id = instance["InstanceId"]
                    launch_time = instance["LaunchTime"]
                    state = instance["State"]["Name"]

                    logger.info(f"Checking instance: {instance_id} | State: {state}")

                    # Only consider running or stopped instances
                    if state in ["running", "stopped"]:

                        age_days = (datetime.now(timezone.utc) - launch_time).days

                        if age_days > RETENTION_DAYS:
                            logger.warning(
                                f"Instance {instance_id} is {age_days} days old."
                            )

                            if not DRY_RUN:
                                ec2.terminate_instances(
                                    InstanceIds=[instance_id]
                                )

                            terminated_instances.append(instance_id)

        logger.info(f"Total Instances Checked: {total_instances}")
        logger.info(f"Instances Marked for Termination: {len(terminated_instances)}")

        return {
            "statusCode": 200,
            "body": {
                "total_snapshots": total_snapshots,
                "total_instances_checked": total_instances,
                "terminated_instances": terminated_instances,
                "dry_run": DRY_RUN
            }
        }

    except Exception as e:
        logger.error(f"Error occurred: {str(e)}")
        raise e
 # -----------------------------
    # Send SNS Notification
    # -----------------------------
    message = f"""
Environment: {os.environ['ENVIRONMENT']}

Deleted Instances:
{deleted_instances}

Deleted Snapshots:
{deleted_snapshots}
"""

    sns.publish(
        TopicArn=SNS_TOPIC_ARN,
        Subject="EC2 & Snapshot Cleanup Report",
        Message=message
    )

    return {
        "statusCode": 200,
        "body": "Cleanup Completed"
    }