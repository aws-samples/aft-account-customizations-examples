#!/bin/bash

echo "Executing Post-API Helpers"
echo "---------------------"
echo "---------------------"
echo "---------------------Get Child Account Number---------------------"
accountnumber=$(aws sts get-caller-identity --query Account --output text)
regionCidr=$(aws ssm get-parameter --name "/aft/account-request/custom-fields/region"  --query Parameter.Value --output text)
ipamApiGtw=$(aws ssm get-parameter --name "/aft/account-request/custom-fields/ipamapigtw"  --query Parameter.Value --output text)
ipamLambda=$(aws ssm get-parameter --name "/aft/account-request/custom-fields/ipamlambda"  --query Parameter.Value --output text)
echo "accountnumber: $accountnumber"
echo "---------------------"
echo "---------------------"
echo "---------------------Change AWS_PROFILE=AFT-TARGET-admin---------------------"
export AWS_PROFILE=aft-target
echo "aws sts get-caller-identity"
aws sts get-caller-identity
echo "---------------------"
echo "---------------------"
echo "---------------------Access folder: CD \API_Helpers---------------------"
cd $DEFAULT_PATH/$CUSTOMIZATION/api_helpers/
echo "---------------------Done!---------------------"
echo "---------------------"
echo "---------------------"
echo "---------------------Get path_store, cidr_block and current_VPC_ID variables---------------------"
path_store="/$accountnumber/vpc/cidr"
cidr_block=`aws ssm get-parameter --name $path_store  --query Parameter.Value --output text`
current_VPC_ID=`aws ec2 describe-vpcs --query "Vpcs[?CidrBlock=='$cidr_block'].VpcId" --output text`
echo "path_store: $path_store"
echo "cidr_block: $cidr_block"
echo "current_VPC_ID: $current_VPC_ID"

echo "---------------------Change AWS_PROFILE=SHARED-management-admin---------------------"
export AWS_PROFILE=aft-management
echo "aws sts get-caller-identity"
aws sts get-caller-identity
echo "aws sts get-caller-identity"
echo "---------------------Executing ./update_cidr.py---------------------"
response=$(python3 ./update_cidr.py $current_VPC_ID $cidr_block $regionCidr $ipamApiGtw $ipamLambda)
echo "---------------------Done!---------------------"
echo "---------------------"
echo "---------------------"
echo "---------------------print python response!---------------------"
echo $response

echo "---------------------Accessing AFT Management Account---------------------"
export AWS_PROFILE=aft-management
aws sts get-caller-identity
echo "---------------------Criando SSM Pameter Store Jinja via bash ---------------------"
jinja_json="{\"environment\":\"dev\",\"workloadAccount\":\"$accountnumber\"}"
aws ssm put-parameter --name "/dev/terraform-parameters/jinja" --value $jinja_json --type "String" --overwrite