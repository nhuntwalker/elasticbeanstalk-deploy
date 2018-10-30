#!/bin/bash
set -e

# Gather secondary artifacts
RDS_SECURITY_GROUP_ID=$(aws rds describe-db-instances\
    --query 'DBInstances[?starts_with(DBName, `'$DB_INSTANCE_NAME'`)].VpcSecurityGroups[0].VpcSecurityGroupId'\
    --output text)

EBS_SECURITY_GROUP=$(aws elasticbeanstalk describe-configuration-settings\
    --application-name $APP_NAME\
    --environment-name $APP_ENV_NAME\
    --query 'ConfigurationSettings[0].OptionSettings[?contains(Namespace, `aws:autoscaling:launchconfiguration`) && contains(OptionName, `SecurityGroups`)].Value'\
    --output text)

BEANSTALK_BUCKET_NAME=$(aws elasticbeanstalk create-storage-location --output text)

aws ec2 revoke-security-group-ingress\
    --group-id $RDS_SECURITY_GROUP_ID\
    --protocol tcp\
    --port $DB_PORT\
    --source-group $EBS_SECURITY_GROUP

aws rds delete-db-instance\
    --db-instance-identifier $DB_INSTANCE_ID\
    --skip-final-snapshot

aws elasticbeanstalk delete-application\
    --application-name $APP_NAME\
    --terminate-env-by-force



