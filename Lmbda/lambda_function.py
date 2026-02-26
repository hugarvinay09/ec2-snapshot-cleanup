import boto3
import datetime
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

ec2 = boto3.client('ec2')

def lambda_handler(event, context):
    try:
        response = ec2.describe_snapshots(OwnerIds=['self'])
        snapshots = response['Snapshots']

        now = datetime.datetime.utcnow()
        one_year_ago = now - datetime.timedelta(days=365)

        for snapshot in snapshots:
            start_time = snapshot['StartTime'].replace(tzinfo=None)

            if start_time < one_year_ago:
                snapshot_id = snapshot['SnapshotId']
                try:
                    logger.info(f"Deleting snapshot: {snapshot_id}")
                    ec2.delete_snapshot(SnapshotId=snapshot_id)
                except Exception as e:
                    logger.error(f"Failed to delete {snapshot_id}: {str(e)}")

        return {"status": "completed"}

    except Exception as e:
        logger.error(f"Error retrieving snapshots: {str(e)}")
        return {"status": "error"}