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

aws --profile "${AWS_PROFILE}" iam put-role-policy \
    --role-name vmimport --policy-name vmimport \
    --policy-document "file://disk-image-file-role-policy.json"
