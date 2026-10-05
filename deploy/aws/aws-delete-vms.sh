#!/usr/bin/env bash

source config.cfg

for VM_ID in 1 2 3; do
   VM_NAME_VAR="VM_NAME_${VM_ID}"
   VM_NAME="${!VM_NAME_VAR}"

   # Get instance id of VM
   instance_id=$(aws --profile "${AWS_PROFILE}" ec2 describe-instances \
                     --filters "Name=tag:Name,Values=$VM_NAME" "Name=instance-state-name,Values=running" \
                     --query "Reservations[*].Instances[*].InstanceId" --output text)

   echo "Terminating instance $VM_NAME"
   aws --profile "${AWS_PROFILE}" ec2 terminate-instances --instance-ids "${instance_id}"
done
