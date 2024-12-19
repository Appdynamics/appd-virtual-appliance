#!/usr/bin/env bash

source config.cfg

cat > disk-image-file-role-policy.json << EOF
{
   "Version":"2012-10-17",
   "Statement":[
      {
         "Effect": "Allow",
         "Action": [
            "s3:GetBucketLocation",
            "s3:GetObject",
            "s3:ListBucket"
         ],
         "Resource": [
            "arn:aws:s3:::${IMAGE_IMPORT_BUCKET}",
            "arn:aws:s3:::${IMAGE_IMPORT_BUCKET}/*"
         ]
      },
      {
         "Effect": "Allow",
         "Action": [
            "ec2:ModifySnapshotAttribute",
            "ec2:CopySnapshot",
            "ec2:RegisterImage",
            "ec2:Describe*"
         ],
         "Resource": "*"
     }
   ]
}
EOF


cat > disk-image-file-role-trust-policy.json << EOF
{
   "Version": "2012-10-17",
   "Statement": [
      {
         "Effect": "Allow",
         "Principal": { "Service": "vmie.amazonaws.com" },
         "Action": "sts:AssumeRole",
         "Condition": {
            "StringEquals":{
               "sts:Externalid": "vmimport"
            }
         }
      }
   ]
}
EOF

# Check if role exists
ROLE_EXISTS=$(aws iam get-role --role-name vmimport 2>&1 || echo "Role does not exist")

if [[ "$ROLE_EXISTS" == *"Role does not exist"* ]]; then
  # Create the role if it does not exist
  aws iam create-role --role-name vmimport --assume-role-policy-document "file://disk-image-file-role-trust-policy.json"
fi

aws --profile ${AWS_PROFILE} iam put-role-policy \
    --role-name vmimport --policy-name ${POLICY_ROLE_NAME} \
    --policy-document "file://disk-image-file-role-policy.json"
