#!/usr/bin/env bash

source ../config.cfg

data_disk_name="/dev/sdb"

output_file="vm_details.yaml"
existing_vms=("$VM_NAME_1" "$VM_NAME_2" "$VM_NAME_3")

echo "---" > "$output_file"

for i in "${!existing_vms[@]}"
do
   existing_vm=${existing_vms[$i]}
   data_disk=""

   printf "'%s':\n" "${existing_vm//\'/\'\'}" >> "$output_file"

   # Get instance id of VM
   instance_id=$(aws --profile "${AWS_PROFILE}" ec2 describe-instances \
                     --filters "Name=tag:Name,Values=$existing_vm" "Name=instance-state-name,Values=running" \
                     --query "Reservations[*].Instances[*].InstanceId" --output text)

   if [ $? -eq 0 ] && [ -n "$instance_id" ]; then
      echo "Instance id for $existing_vm is $instance_id"
   else
      echo "Failed to get instance id for VM $existing_vm."
      continue
   fi

   echo "  - instance_id: $instance_id" >> "$output_file"

   # Get network interface of the VM
   network_intf_id=$(aws --profile "${AWS_PROFILE}" ec2 describe-instances \
                         --instance-ids "${instance_id}" \
                         --filters "Name=instance-state-name,Values=running" \
                         --query "Reservations[].Instances[].NetworkInterfaces[].NetworkInterfaceId" \
                         --output text)

   if [ $? -eq 0 ] && [ -n "$network_intf_id" ]; then
      echo "Network intf id for $existing_vm is $network_intf_id"
   else
      echo "Failed to get network interface id for VM $existing_vm."
   fi

   echo "  - network_intf_id: $network_intf_id" >> "$output_file"

   # Get attachment if of the network interface
   attachment_id=$(aws --profile "${AWS_PROFILE}" ec2 describe-network-interfaces \
                       --network-interface-ids "${network_intf_id}" \
                       --query 'NetworkInterfaces[].Attachment.AttachmentId' --output text)

   if [ $? -eq 0 ] && [ -n "$attachment_id" ]; then
      echo "Attachment id for $existing_vm is $attachment_id"
   else
      echo "Failed to get attachment id for VM $existing_vm."
   fi

   echo "  - attachment_id: $attachment_id" >> "$output_file"

   # Get data disk of VM 
   echo "  - data_disk_name: $data_disk_name" >> "$output_file"
   disk_name=$(aws --profile "${AWS_PROFILE}" ec2 describe-instances \
                   --instance-ids "${instance_id}" \
                   --filters "Name=instance-state-name,Values=running" \
                   --query "Reservations[*].Instances[*].BlockDeviceMappings[?DeviceName=='$data_disk_name'].Ebs.VolumeId" \
                   --output text)

   if [ $? -eq 0 ] && [ -n "$disk_name" ]; then
      echo "Data disk for $existing_vm is $disk_name"
   else
      echo "Failed to get data disk for VM $existing_vm."
   fi

   echo "  - data_disk: $disk_name" >> "$output_file"

   echo "Created $output_file with config details"

done
