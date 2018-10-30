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
    --master-user-password $DB_PASSWORD\
    --vpc-security-group-ids $RDS_SG_VPC_ID > /dev/null

RDS_SECURITY_GROUP_ID=$(aws rds describe-db-instances\
    --query 'DBInstances[?starts_with(DBName, `'$DB_INSTANCE_NAME'`)].VpcSecurityGroups[0].VpcSecurityGroupId'\
    --output text)

DB_HOST=$(aws rds describe-db-instances\
    --query 'DBInstances[?starts_with(DBName, `'$DB_INSTANCE_NAME'`)].Endpoint.Address'\
    --output text)

CURRENT_IP=$(dig +short myip.opendns.com @resolver1.opendns.com)

export DATABASE_URL="postgres://$DB_USERNAME:$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_INSTANCE_NAME"

# Create the beanstalk

BEANSTALK_BUCKET_NAME=$(aws elasticbeanstalk create-storage-location --output text)

aws s3 cp $ARCHIVE_PATH s3://$BEANSTALK_BUCKET_NAME

aws elasticbeanstalk create-application-version\
    --application-name $APP_NAME\
    --version-label $APP_VERSION\
    --source-bundle S3Bucket="$BEANSTALK_BUCKET_NAME",S3Key="$FILENAME"\
    --auto-create-application > /dev/null

aws elasticbeanstalk create-environment\
    --application-name $APP_NAME\
    --environment-name $APP_ENV_NAME\
    --version-label $APP_VERSION\
    --solution-stack-name "$APP_STACK"\
    --option-settings Namespace=aws:elasticbeanstalk:application:environment,OptionName=DATABASE_URL,Value=$DATABASE_URL > /dev/null

echo 'Run the following *after* beanstalk is done (give it a few minutes):
--------
EBS_SECURITY_GROUP=$(aws elasticbeanstalk describe-configuration-settings\
    --application-name $APP_NAME\
    --environment-name $APP_ENV_NAME\
    --query "ConfigurationSettings[0].OptionSettings[?contains(Namespace, `aws:autoscaling:launchconfiguration`) && contains(OptionName, `SecurityGroups`)].Value"\
    --output text)

RDS_SECURITY_GROUP_ID=$(aws rds describe-db-instances\
    --query "DBInstances[?starts_with(DBName, `$DB_INSTANCE_NAME`)].VpcSecurityGroups[0].VpcSecurityGroupId"\
    --output text)

aws ec2 authorize-security-group-ingress\
    --group-id $RDS_SECURITY_GROUP_ID\
    --protocol tcp\
    --port $DB_PORT\
    --cidr $CURRENT_IP/32

aws ec2 authorize-security-group-ingress\
    --group-id $RDS_SECURITY_GROUP_ID\
    --protocol tcp\
    --port $DB_PORT\
    --source-group $EBS_SECURITY_GROUP > /dev/null

aws ec2 authorize-security-group-ingress\
    --group-name $EBS_SECURITY_GROUP\
    --protocol tcp\
    --port $DB_PORT\
    --source-group $RDS_SECURITY_GROUP_ID > /dev/null
'