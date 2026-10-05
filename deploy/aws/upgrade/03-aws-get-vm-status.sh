#!/usr/bin/env bash

source ../config.cfg

vm_details="vm_details.yaml"

for VM_ID in 1 2 3; do
   VM_NAME_VAR="VM_NAME_${VM_ID}"
   VM_NAME="${!VM_NAME_VAR}"

   instance_id=$(VM_NAME="$VM_NAME" yq e '.[strenv(VM_NAME)][0].instance_id' "$vm_details")

   echo "Get instance $VM_NAME details"
   aws --profile "${AWS_PROFILE}" ec2 describe-instances \
       --instance-ids "${instance_id}" \
       --query 'Reservations[*].Instances[*].{Name:Tags[?Key==`Name`].Value|[0], State:State.Name}' --output table

done

echo "Wait for instances to terminate before creating new VMs"
