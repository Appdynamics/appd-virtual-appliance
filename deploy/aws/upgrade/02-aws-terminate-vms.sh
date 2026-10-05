#!/usr/bin/env bash

source ../config.cfg

vm_details="vm_details.yaml"

for VM_ID in 1 2 3; do
   VM_NAME_VAR="VM_NAME_${VM_ID}"
   VM_NAME="${!VM_NAME_VAR}"

   instance_id=$(VM_NAME="$VM_NAME" yq e '.[strenv(VM_NAME)][0].instance_id' "$vm_details")
   network_intf_id=$(VM_NAME="$VM_NAME" yq e '.[strenv(VM_NAME)][1].network_intf_id' "$vm_details")
   data_disk=$(VM_NAME="$VM_NAME" yq e '.[strenv(VM_NAME)][4].data_disk' "$vm_details")

   echo "Terminating instance $VM_NAME"
   echo "Network instance $network_intf_id and data disk volume $data_disk will be retained"
   aws --profile "${AWS_PROFILE}" ec2 terminate-instances --instance-ids "${instance_id}"
done
