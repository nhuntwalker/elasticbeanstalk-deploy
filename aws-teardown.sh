#!/bin/bash
set -e

# RDS variables
export DB_INSTANCE_NAME='tutorial_db'
export DB_INSTANCE_ID='tutorial-db-instance'
export DB_INSTANCE_CLASS='db.t2.micro'
export DB_ENGINE='postgres'
export DB_USERNAME='tutorialuser'
export DB_PASSWORD='potatosalad'
export DB_PORT=5432

# EBS variables
export APP_NAME='flask-expenses'
export APP_ENV_NAME='flask-expenses-env'
export APP_STACK="64bit Amazon Linux 2018.03 v2.7.4 running Python 3.6"
export APP_VERSION="latest"

# Gather security groups
RDS_SECURITY_GROUP_ID=$(aws rds describe-db-instances\
    --query 'DBInstances[?starts_with(DBName, `'$DB_INSTANCE_NAME'`)].VpcSecurityGroups[0].VpcSecurityGroupId'\
    --output text)

EBS_SECURITY_GROUP=$(aws elasticbeanstalk describe-configuration-settings\
    --application-name $APP_NAME\
    --environment-name $APP_ENV_NAME\
    --query 'ConfigurationSettings[0].OptionSettings[?contains(Namespace, `aws:autoscaling:launchconfiguration`) && contains(OptionName, `SecurityGroups`)].Value'\
    --output text)

aws rds delete-db-instance\
    --db-instance-identifier $DB_INSTANCE_ID\
    --skip-final-snapshot

aws elasticbeanstalk delete-application\
    --application-name $APP_NAME\
    --terminate-env-by-force
