#!/usr/bin/env bash

source config.cfg

PROFILE_EXISTS=$(aws configure list-profiles | grep -w $AWS_PROFILE)

if [ -n "$PROFILE_EXISTS" ]; then
  echo "Profile '$AWS_PROFILE' already exists."
else
  echo "Creating AWS profile ${AWS_PROFILE} ..."
  aws configure --profile ${AWS_PROFILE}
fi
