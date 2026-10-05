#!/usr/bin/env bash
# shellcheck disable=SC2181,SC2086,SC1091

### Config ###
# shellcheck source-path=SCRIPTDIR
source ../config.cfg 
#############

vm_details="vm_details.yaml"

AMI_ID=$(awk -F ': ' '/ami_id/ {print $2}' ../ami.id)
if [ -z "${AMI_ID}" ]; then
    echo "Missing required AMI_ID value"
    exit 1
fi

echo "Creating the VMs ..."
for VM_ID in 1 2 3; do
    VM_NAME_VAR="VM_NAME_${VM_ID}"
    VM_NAME="${!VM_NAME_VAR}"

    cat > user-data.ec2 <<EOF
#cloud-config
ssh_pwauth: True
appdos:
  bootstrap:
    netplan:
      dhcp4: true
      dhcp6: false
EOF

    network_intf_id=$(VM_NAME="$VM_NAME" yq e '.[strenv(VM_NAME)][1].network_intf_id' "$vm_details")
    data_disk=$(VM_NAME="$VM_NAME" yq e '.[strenv(VM_NAME)][4].data_disk' "$vm_details")

    # requires Nitro instance types
    new_instance_id=$(aws --profile "${AWS_PROFILE}" ec2 run-instances \
                          --image-id "$AMI_ID" \
                       	  --instance-type "${VM_TYPE}" \
                          --network-interfaces "[{\"NetworkInterfaceId\":\"${network_intf_id}\",\"DeviceIndex\":0}]" \
                          --block-device-mappings \
                          "DeviceName=/dev/sda1,Ebs={VolumeSize=${VM_OS_DISK},VolumeType=gp3}" \
                  	  --user-data file://user-data.ec2 \
                          --no-cli-pager \
                          --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${VM_NAME}},${TAGS}]" \
                          --query "Instances[0].InstanceId" --output text)

    echo "Waiting for instance to come to running state"
    aws --profile "${AWS_PROFILE}" ec2 wait instance-running --instance-ids "${new_instance_id}"

    # Attach the data disk
    aws --profile "${AWS_PROFILE}" ec2 attach-volume \
        --instance-id "${new_instance_id}" \
        --volume-id "${data_disk}" \
        --device "/dev/sdb" 

done
