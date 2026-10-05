#!/usr/bin/env bash

source config.cfg

echo "Uploading the image ..."
aws --profile "${AWS_PROFILE}" s3 cp "${APPD_RAW_IMAGE}" "s3://${IMAGE_IMPORT_BUCKET}/${APPD_RAW_IMAGE}"
aws --profile "${AWS_PROFILE}" s3 ls "s3://${IMAGE_IMPORT_BUCKET}/${APPD_RAW_IMAGE}"
