#!/bin/bash

echo "Executing Post-API Helpers"
echo "---------------------"
echo "---------------------"
echo "---------------------Get Child Account Number---------------------"
accountnumber=$(aws sts get-caller-identity --query Account --output text)
regionCidr=$(aws ssm get-parameter --name "/aft/account-request/custom-fields/region"  --query Parameter.Value --output text)
ipamApiGtw=$(aws ssm get-parameter --name "/aft/account-request/custom-fields/ipamapigtw"  --query Parameter.Value --output text)
ipamLambda=$(aws ssm get-parameter --name "/aft/account-request/custom-fields/ipamlambda"  --query Parameter.Value --output text)
echo $accountnumber
echo "---------------------"
echo "---------------------"
echo "---------------------Change AWS_PROFILE=AFT-TARGET-admin---------------------"
export AWS_PROFILE=aft-target
echo "aws sts get-caller-identity"
aws sts get-caller-identity
echo "aws sts get-caller-identity"
echo "---------------------"
echo "---------------------"
echo "---------------------Access folder: CD \API_Helpers---------------------"
cd $DEFAULT_PATH/$CUSTOMIZATION/api_helpers/
echo "---------------------Done!---------------------"
echo "---------------------"
echo "---------------------"
echo "---------------------Get pathStore, CidrBlock and currentVPCID variables---------------------"
pathStore="/$accountnumber/vpc/cidr"
CidrBlock=`aws ssm get-parameter --name "/$accountnumber/vpc/cidr"  --query Parameter.Value --output text`
currentVPCID=`aws ec2 describe-vpcs --query "Vpcs[?CidrBlock=='$CidrBlock'].VpcId" --output text`
echo "pathStore: $pathStore"
echo "CidrBlock: $CidrBlock"
echo "currentVPCID: $currentVPCID"
echo "---------------------Change AWS_PROFILE=SHARED-management-admin---------------------"
export AWS_PROFILE=aft-management
echo "aws sts get-caller-identity"
aws sts get-caller-identity
echo "aws sts get-caller-identity"
echo "---------------------Executing ./update_cidr.py---------------------"
response=$(python3 ./update_cidr.py $currentVPCID $CidrBlock $regionCidr $ipamApiGtw $ipamLambda)
echo "---------------------Done!---------------------"
echo "---------------------"
echo "---------------------"
echo "---------------------print python response!---------------------"
echo $response
echo "---------------------Acessando conta AFT ---------------------"
export AWS_PROFILE=aft-management
aws sts get-caller-identity
echo "---------------------Criando SSM Pameter Store Jinja via bash ---------------------"
jinja_json="{\"environment\":\"hml\",\"workloadAccount\":\"$accountnumber\"}"
aws ssm put-parameter --name "/hml/terraform-parameters/jinja" --value $jinja_json --type "String" --overwrite