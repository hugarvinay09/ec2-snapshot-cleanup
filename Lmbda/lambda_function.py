import boto3
import logging
from datetime import datetime, timedelta, timezone

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    Main Lambda handler to find and delete EC2 snapshots older than one year.
    """
    # 1. Connect to the AWS EC2 service
    ec2 = boto3.client('ec2')
    
    # Calculate the cutoff date (365 days ago from now)
    # We use timezone-aware objects to match the AWS StartTime format
    now = datetime.now(timezone.utc)
    cutoff_date = now - timedelta(days=365)
    
    deleted_count = 0
    error_count = 0

    try:
        # 2. Retrieves a list of all EC2 snapshots owned by the account
        # 'self' ensures we don't try to delete public snapshots owned by others
        response = ec2.describe_snapshots(OwnerIds=['self'])
        snapshots = response.get('Snapshots', [])
        
        logger.info(f"Found {len(snapshots)} total snapshots owned by this account.")

        for snapshot in snapshots:
            snapshot_id = snapshot['SnapshotId']
            start_time = snapshot['StartTime']

            # 3. Filters snapshots older than one year
            if start_time < cutoff_date:
                try:
                    # 4. & 5. Logs and attempts to delete identified old snapshots
                    logger.info(f"Deleting snapshot: {snapshot_id} (Created: {start_time})")
                    ec2.delete_snapshot(SnapshotId=snapshot_id)
                    deleted_count += 1
                    
                except Exception as e:
                    # 6. Basic error handling for specific deletion API calls
                    # (e.g., if the snapshot is currently in use by an AMI)
                    logger.error(f"Failed to delete {snapshot_id}: {str(e)}")
                    error_count += 1

        logger.info(f"Cleanup complete. Deleted: {deleted_count}, Errors: {error_count}")

    except Exception as e:
        # 6. Basic error handling for the initial describe_snapshots call
        logger.error(f"Fatal error during snapshot retrieval: {str(e)}")
        raise e

    return {
        'statusCode': 200,
        'body': f"Successfully processed snapshots. Deleted: {deleted_count}"
    }