#!/bin/bash
set -e

# RDS variables
export DB_INSTANCE_NAME='XXXX_XXXX'
export DB_INSTANCE_ID='XXXX-XXXX'
export DB_INSTANCE_CLASS='XXXX'
export DB_ENGINE='XXXXX'
export DB_USERNAME='XXXXX'
export DB_PASSWORD='XXXXX'
export DB_PORT=00000

# EBS variables
export APP_NAME='XXXXX'
export APP_ENV_NAME='XXXXX'
export APP_STACK="64bit Amazon Linux 2018.03 v2.7.4 running Python 3.6"
export APP_VERSION="XXXXX"

# S3 variables
export FILENAME='XXXX.zip'
export ARCHIVE_PATH='/path/to/zipped/file/to/deploy/'$FILENAME

TIME_START=$(date +%s)
./aws-deploy.sh
TIME_END=$(date +%s)

echo "Artifact provisioning finished in $(expr $TIME_END - $TIME_START) seconds"
