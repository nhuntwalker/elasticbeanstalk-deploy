#!/bin/bash
set -e


# `aws configure` with IAM credentials in your favorite region

aws rds create-db-instance\
    --allocated-storage 20\
    --db-name $DB_INSTANCE_NAME\
    --db-instance-identifier $DB_INSTANCE_ID\
    --db-instance-class $DB_INSTANCE_CLASS\
    --engine $DB_ENGINE\
    --master-username $DB_USERNAME\
    --master-user-password $DB_PASSWORD
    --vpc-security-group-ids $RDS_SG_VPC_ID

RDS_SG_ID=$(aws rds describe-db-instances\
    --query 'DBInstances[?starts_with(DBName, `'$DB_INSTANCE_NAME'`)].VpcSecurityGroups[0].VpcSecurityGroupId'\
    --output text)

DB_HOST=$(aws rds describe-db-instances\
    --query 'DBInstances[?starts_with(DBName, `'$DB_INSTANCE_NAME'`)].Endpoint.Address'\
    --output text)

export DATABASE_URL="postgres://$DB_USERNAME:$DB_PASSWORD@$DB_HOST:$DB_PORT"

# Create the S3 bucket and upload your zip file
aws s3 mb s3://$BUCKET_NAME
aws s3 cp $ARCHIVE_PATH s3://$BUCKET_NAME

BEANSTALK_ROLE=$(aws iam list-roles\
    --query 'Roles[?contains(RoleName, `aws-elasticbeanstalk-ec2-role`)].Arn'\
    --output text)

aws s3api put-bucket-policy --bucket $BUCKET_NAME --policy $BUCKET_POLICY

S3_ACCESS_POLICY_ID=$(aws iam get-policy\
    --policy-arn 'arn:aws:iam::aws:policy/AmazonS3FullAccess'\
    --query 'Policy.PolicyId'\
    --output text)

S3_ACCESS_POLICY_TEXT=

# Create the beanstalk

aws elasticbeanstalk create-application\
    --application-name flask-expenses\
    --description "Application for tracking your expenses"

aws elasticbeanstalk create-environment\
    --application-name flask-expenses\
    --environment-name expenses-env\
    --version-label v1\
    --solution-stack-name "64bit Amazon Linux 2018.03 v2.7.4 running Python 3.6"