#!/usr/bin/env bash
#shellcheck disable=SC2046

source config.cfg

if aws --profile ${AWS_PROFILE} s3api head-bucket --bucket ${IMAGE_IMPORT_BUCKET}; then
    echo "Bucket exists ${IMAGE_IMPORT_BUCKET}"
else
    echo "Creating S3 bucket to upload image ..."
    aws --profile ${AWS_PROFILE} s3api create-bucket \
        --bucket ${IMAGE_IMPORT_BUCKET} \
        --region ${AWS_REGION} \
        --create-bucket-configuration LocationConstraint=${AWS_REGION}

    echo "Created bucket"
    aws --profile ${AWS_PROFILE} s3 ls | grep ${IMAGE_IMPORT_BUCKET}
fi
