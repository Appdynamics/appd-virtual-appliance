#!/usr/bin/env bash
#shellcheck disable=SC2181,SC2086,SC1091,SC2046

### Config ###
# shellcheck source-path=SCRIPTDIR
source config.cfg 
#############

SNAPID=$(awk -F ': ' '/snapshot_id/ {print $2}' snapshot.id)
if [ -z "${SNAPID}" ]; then
    echo "missing required SnapshotId value"
    exit 1
fi

echo "Using snapshot ..."
aws --profile "${AWS_PROFILE}" ec2 describe-snapshots --snapshot-ids "$SNAPID"

AMI_ID=$(aws --profile "${AWS_PROFILE}" ec2 register-image \
   --architecture x86_64 \
   --description "AppD OnPrem Virtual Appliance for EC2" \
   --ena-support \
   --sriov-net-support simple \
   --virtualization-type hvm \
   --boot-mode uefi \
   --imds-support v2.0 \
   --name "${APPD_IMAGE_NAME}" \
   --root-device-name /dev/sda1 \
   --block-device-mapping "DeviceName=/dev/sda1,Ebs={SnapshotId=$SNAPID}" \
   --query 'ImageId' \
   --output text)

echo "AMI ID: $AMI_ID"
echo "ami_id: $AMI_ID" > ami.id
