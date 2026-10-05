#!/usr/bin/env bash
#shellcheck disable=SC2046

source config.cfg

S3URL="s3://${IMAGE_IMPORT_BUCKET}/${APPD_RAW_IMAGE}"

IMPORT_TASK_ID=$(aws --profile "${AWS_PROFILE}" ec2 import-snapshot --disk-container "Description=$(basename -- "$S3URL"),Format=RAW,Url=${S3URL}" --query "ImportTaskId" --output text)
echo "Import Task ID: $IMPORT_TASK_ID"

echo "Waiting for import task to proceed..."
sleep 30

aws --profile "${AWS_PROFILE}" ec2 describe-import-snapshot-tasks --import-task-ids "$IMPORT_TASK_ID"

check_status() {
  STATUS=$(aws --profile "${AWS_PROFILE}" ec2 describe-import-snapshot-tasks --import-task-ids "$IMPORT_TASK_ID" --query "ImportSnapshotTasks[0].SnapshotTaskDetail.Status" --output text)
  echo "Current Status: $STATUS"
}

while true; do
  check_status
  if [ "$STATUS" == "completed" ]; then
    echo "Snapshot import completed."
    SNAPSHOT_ID=$(aws --profile "${AWS_PROFILE}" ec2 describe-import-snapshot-tasks --import-task-ids "$IMPORT_TASK_ID" --query "ImportSnapshotTasks[0].SnapshotTaskDetail.SnapshotId" --output text)
    echo "Snapshot ID: $SNAPSHOT_ID"
    echo "snapshot_id: $SNAPSHOT_ID" > snapshot.id
    break
  elif [ "$STATUS" == "deleted" ] || [ "$STATUS" == "deleting" ] || [ "$STATUS" == "failed" ]; then
    echo "Snapshot import failed or was deleted."
    break
  fi
  sleep 30
done
