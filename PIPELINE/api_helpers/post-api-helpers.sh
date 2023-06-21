#!/bin/bash

echo "Executing Post-API Helpers"
echo "---------------------"
echo "---------------------"
echo "---------------------Get Child Account Number---------------------"
accountnumber=$(aws sts get-caller-identity --query Account --output text)
echo "accountnumber: $accountnumber"
export AWS_PROFILE=aft-target
echo "aws sts get-caller-identity"
aws sts get-caller-identity

echo "---------------------Installing terraform and jinja2---------------------"
sudo yum install -y yum-utils shadow-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum -y install terraform

echo "---------------------Change AWS_PROFILE=aft-management-admin---------------------"
export AWS_PROFILE=aft-management-admin

echo "---------------------Ambiente DEV---------------------"
echo "---------------------Executando terraform application pipeline---------------------"
chmod +x $DEFAULT_PATH/$CUSTOMIZATION/api_helpers/application_script/terraform-deploy-dev.sh
$DEFAULT_PATH/$CUSTOMIZATION/api_helpers/application_script/terraform-deploy-dev.sh


echo "---------------------Ambiente HML---------------------"
echo "---------------------Executando terraform application pipeline---------------------"
chmod +x $DEFAULT_PATH/$CUSTOMIZATION/api_helpers/application_script/terraform-deploy-hml.sh
$DEFAULT_PATH/$CUSTOMIZATION/api_helpers/application_script/terraform-deploy-hml.sh

echo "---------------------Ambiente PRD---------------------"
echo "---------------------Executando terraform application pipeline---------------------"
chmod +x $DEFAULT_PATH/$CUSTOMIZATION/api_helpers/application_script/terraform-deploy-prd.sh
$DEFAULT_PATH/$CUSTOMIZATION/api_helpers/application_script/terraform-deploy-prd.sh