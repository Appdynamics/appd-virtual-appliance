#!/usr/bin/env bash
# shellcheck disable=SC2181,SC2086,SC1091

### Config ###
# shellcheck source-path=SCRIPTDIR
source config.cfg 
#############


# check if vpc exists
vpcID=$(aws --profile ${AWS_PROFILE} ec2 describe-vpcs --output text \
    --filters Name=tag-value,Values=${VPC_NAME} --query 'Vpcs[*].VpcId')

if [ -z "$vpcID" ]; then
    echo "Did not find a vpc with name $VPC_NAME, creating"
    # create the vpc
    aws --profile ${AWS_PROFILE} ec2 create-vpc --cidr ${VPC_CIDR} \
        --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=${VPC_NAME}},${TAGS}]"
    if [ "$?" != 0 ]; then
        echo "error with create-vpc command"
        exit 1
    fi
    sleep 5
    aws --profile ${AWS_PROFILE} ec2 describe-vpcs --output json --filters Name=tag-value,Values=${VPC_NAME}
fi

# get vpcID
vpcID=$(aws --profile ${AWS_PROFILE} ec2 describe-vpcs --output text --filters Name=tag-value,Values=${VPC_NAME} --query 'Vpcs[*].VpcId')
if [ -z "$vpcID" ]; then
    echo "Did not find a vpc with name $VPC_NAME"
    exit 1
fi

# create a subnet in the vpc
subnetID=$(aws --profile ${AWS_PROFILE} ec2 describe-subnets --output text --filters Name=tag-value,Values="${SUBNET_NAME}" --query 'Subnets[*].SubnetId')
if [ -z "${subnetID}" ]; then
    echo "Did not find a subnet with name $SUBNET_NAME, creating"
    aws --profile ${AWS_PROFILE} ec2 create-subnet --cidr ${SUBNET_CIDR} \
        --vpc-id "$vpcID" \
        --tag-specifications \
        "ResourceType=subnet,Tags=[{Key=Name,Value=${SUBNET_NAME}},${TAGS}]"
    if [ "$?" != 0 ]; then
        echo "error with create-subnet command"
        exit 1
    fi
    sleep 5
    aws --profile ${AWS_PROFILE} ec2 describe-subnets --output json --filters Name=tag-value,Values="${SUBNET_NAME}"
    subnetID=$(aws --profile ${AWS_PROFILE} ec2 describe-subnets --output text --filters Name=tag-value,Values="${SUBNET_NAME}" --query 'Subnets[*].SubnetId')
fi

# create an internet gateway
igwID=$(aws --profile ${AWS_PROFILE} ec2 describe-internet-gateways --output text --filters Name=tag-value,Values=${IGW_NAME} --query 'InternetGateways[*].InternetGatewayId')
if [ -z "$igwID" ]; then
    echo "Did not find an Internet Gateway with name $IGW_NAME, creating"
    aws --profile ${AWS_PROFILE} ec2 create-internet-gateway \
        --tag-specifications \
         "ResourceType=internet-gateway,Tags=[{Key=Name,Value=${IGW_NAME}},${TAGS}]"
    if [ "$?" != 0 ]; then
        echo "error with create-internet-gateway command"
        exit 1
    fi
    sleep 5
    aws --profile ${AWS_PROFILE} ec2 describe-internet-gateways --output json --filters Name=tag-value,Values=${IGW_NAME}
    igwID=$(aws --profile ${AWS_PROFILE} ec2 describe-internet-gateways --output text --filters Name=tag-value,Values=${IGW_NAME} --query 'InternetGateways[*].InternetGatewayId')
fi

# associate internet gateway to vpc
igw_VpcID=$(aws --profile ${AWS_PROFILE} ec2 describe-internet-gateways --output text --filters Name=tag-value,Values=${IGW_NAME}  --query 'InternetGateways[*].Attachments[*].VpcId')
if [ -z "$igw_VpcID" ] || [ "$igw_VpcID" != "$vpcID" ]; then
    echo "Did not find vpc associated with Internet Gateway $IGW_NAME, associating"
    aws --profile ${AWS_PROFILE} ec2 attach-internet-gateway \
        --internet-gateway-id "${igwID}" --vpc-id "${vpcID}"
    if [ "$?" != 0 ]; then
        echo "error attaching internet gateway ${igwID} to vpc ${vpcID}"
        exit 1
    fi
    aws --profile ${AWS_PROFILE} ec2 describe-internet-gateways --output json --filters Name=tag-value,Values=${IGW_NAME}
fi

# create a route table
rtID=$(aws --profile ${AWS_PROFILE} ec2 describe-route-tables --output text --filters Name=tag-value,Values=${RT_NAME} --query 'RouteTables[*].RouteTableId')
if [ -z "$rtID" ]; then
    echo "Did not find a route table with the name $RT_NAME, creating"
    aws --profile ${AWS_PROFILE} ec2 create-route-table --vpc-id "${vpcID}" \
        --tag-specifications \
        "ResourceType=route-table,Tags=[{Key=Name,Value=${RT_NAME}},${TAGS}]"
    if [ "$?" != 0 ]; then
        echo "error with create-route-table command"
        exit 1
    fi
    sleep 5
    aws --profile ${AWS_PROFILE} ec2 describe-route-tables --output json --filters Name=tag-value,Values=${RT_NAME}
    rtID=$(aws --profile ${AWS_PROFILE} ec2 describe-route-tables --output text --filters Name=tag-value,Values=${RT_NAME} --query 'RouteTables[*].RouteTableId')
fi

# add internet gateway to routing table
mapfile -t routes < <(aws --profile ${AWS_PROFILE} ec2 describe-route-tables --output text --filters Name=tag-value,Values=${RT_NAME} --query 'RouteTables[*].Routes[*].DestinationCidrBlock')
inarray=$(echo "${routes[@]}" | grep -o "0.0.0.0/0" | wc -w)
if [ "$inarray" != "1" ]; then
    echo "Did not find default route in routing able $RT_NAME, creating"
    aws --profile ${AWS_PROFILE} ec2 create-route \
        --route-table-id "$rtID" \
        --destination-cidr-block 0.0.0.0/0 --gateway-id "${igwID}"
    if [ "$?" != 0 ]; then
        echo "error with create-route command"
        exit 1
    fi
    sleep 5
    aws --profile ${AWS_PROFILE} ec2 describe-route-tables --output json --filters Name=tag-value,Values=${RT_NAME}
fi

# associate subnet with route table to access internet gateway
mapfile -t assocSubnets < <(aws --profile ${AWS_PROFILE} ec2 describe-route-tables --output text --filters Name=tag-value,Values=${RT_NAME} --query 'RouteTables[*].Associations[*].SubnetId')
inarray=$(echo "${assocSubnets[@]}" | grep -i "${SUBNET_CIDR}" | wc -w)
if [ "$inarray" != "1" ]; then
    echo "Did not find subnet $SUBNET_CIDR associated with routing table $RT_NAME, associating now"
    aws --profile ${AWS_PROFILE} ec2 associate-route-table --route-table-id "${rtID}" --subnet-id "${subnetID}"
    if [ "$?" != 0 ]; then
        echo "error with create-route command"
        exit 1
    fi
    sleep 5
    aws --profile ${AWS_PROFILE} ec2 describe-route-tables --output json --filters Name=tag-value,Values=${RT_NAME}
fi

# create a security group and rules
sgID=$(aws --profile ${AWS_PROFILE} ec2 describe-security-groups --output text --filters Name=tag-value,Values=${SG_NAME} --query 'SecurityGroups[*].GroupId')
if [ -z "$sgID" ]; then
    echo "Did not find a security group with the name $SG_NAME, creating"
    aws --profile ${AWS_PROFILE} ec2 create-security-group --group-name "$SG_NAME" \
        --description "Allow SSH to VMs only via configured VPN Endpoints" \
        --vpc-id "${vpcID}" \
        --tag-specifications \
        "ResourceType=security-group,Tags=[{Key=Name,Value=${SG_NAME}},${TAGS}]"
    if [ "$?" != 0 ]; then
        echo "error with create-security-group command"
        exit 1
    fi
    sleep 5
    aws --profile ${AWS_PROFILE} ec2 describe-security-groups --output json --filters Name=tag-value,Values=${SG_NAME}
    sgID=$(aws --profile ${AWS_PROFILE} ec2 describe-security-groups --output text --filters Name=tag-value,Values=${SG_NAME} --query 'SecurityGroups[*].GroupId')

fi

# create security group rules
# check that we have rule for each vpn endpoint IP
mapfile -t ipRules < <(aws --profile ${AWS_PROFILE} ec2 describe-security-groups --output text --filters Name=tag-value,Values=${SG_NAME} --query 'SecurityGroups[*].IpPermissions[*].IpRanges[*]' | sort | uniq | cut -f1)
for ((i=0; i<${#VPN_IPS[@]}; i++)); do
    vpnIP=${VPN_IPS[$i]}
    inarray=$(echo "${ipRules[@]}" | grep -o "$vpnIP" | wc -w)
    if [ "${inarray}" != "1" ]; then
        aws --profile ${AWS_PROFILE} ec2 authorize-security-group-ingress \
            --group-id "${sgID}" --ip-permissions \
            "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=${vpnIP}}]"  \
            "IpProtocol=tcp,FromPort=443,ToPort=443,IpRanges=[{CidrIp=${vpnIP}}]"
        if [ "$?" != 0 ]; then
            echo "error authorizing security group ingress rules for VPN ${vpnIP}"
        fi
    else
        echo "rules for ${vpnIP} already authorized"
    fi
done

# create security group rule to allow traffic between instances in subnet
inarray=$(echo "${ipRules[@]}" | grep -o "${SUBNET_CIDR}" | wc -w)
if [ "${inarray}" != "1" ]; then
    echo "Adding ingress rule for ${SUBNET_CIDR}"
    aws --profile ${AWS_PROFILE} ec2 authorize-security-group-ingress \
        --group-id "${sgID}"  \
        --protocol "-1" \
        --cidr "${SUBNET_CIDR}"
    if [ "$?" != 0 ]; then
        echo "error authorizing security group ingress rules for subnet ${SUBNET_CIDR}"
    fi
else
    echo "rules for subnet ${SUBNET_CIDR} ingress already authorized"
fi

# create security group rule to allow traffic between instances in subnet
mapfile -t ipEgressRules < <(aws --profile ${AWS_PROFILE} ec2 describe-security-groups --output text --filters Name=tag-value,Values=${SG_NAME} --query 'SecurityGroups[*].IpPermissionsEgress[*].IpRanges[*]' | sort | uniq | cut -f1)

inarray=$(echo "${ipEgressRules[@]}" | grep -o "${SUBNET_CIDR}" | wc -w)
if [ "${inarray}" != "1" ]; then
    echo "Adding egress rule for ${SUBNET_CIDR}"
    aws --profile ${AWS_PROFILE} ec2 authorize-security-group-egress \
        --group-id "${sgID}"  \
        --protocol "-1" \
        --cidr "${SUBNET_CIDR}"
    if [ "$?" != 0 ]; then
        echo "error authorizing security group egress rules for subnet ${SUBNET_CIDR}"
    fi
else
    echo "rules for subnet ${SUBNET_CIDR} egress already authorized"
fi
