#!/usr/bin/env bash

source config.cfg

# Download the ami image to your local with same name ${APPD_RAW_IMAGE}
echo "Uploading the image ..."
aws --profile ${AWS_PROFILE} s3 cp ${APPD_RAW_IMAGE} s3://${IMAGE_IMPORT_BUCKET}/${APPD_RAW_IMAGE}
aws --profile ${AWS_PROFILE} s3 ls s3://${IMAGE_IMPORT_BUCKET}/${APPD_RAW_IMAGE}

#Use rescue-user or any of the SJC linux cluster for faster download and upload
