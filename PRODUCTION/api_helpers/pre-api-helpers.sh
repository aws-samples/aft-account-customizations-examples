#!/bin/bash

echo "Executing Pre-API Helpers"
echo "---------------------"
echo "---------------------"
echo "---------------------Get Child Account Number---------------------"
accountnumber=$(aws sts get-caller-identity --query Account --output text)
accountName=$(aws ssm get-parameter --name "/aft/account-request/custom-fields/project"  --query Parameter.Value --output text)
regionCidr=$(aws ssm get-parameter --name "/aft/account-request/custom-fields/region"  --query Parameter.Value --output text)
ipamApiGtw=$(aws ssm get-parameter --name "/aft/account-request/custom-fields/ipamapigtw"  --query Parameter.Value --output text)
ipamLambda=$(aws ssm get-parameter --name "/aft/account-request/custom-fields/ipamlambda"  --query Parameter.Value --output text)
echo "accountnumber: $accountnumber"
has_parameter_store=`aws ssm get-parameter --name "/$accountnumber/vpc/cidr"  --query Parameter.Value --output text`
echo "---------------------Echo Parameter Store---------------------"
echo $has_parameter_store
echo "---------------------"
echo "---------------------"
echo "---------------------Change AWS_PROFILE=SHARED-management-admin---------------------"
export AWS_PROFILE=aft-management
#export AWS_PROFILE=ct-management
echo "aws sts get-caller-identity"
aws sts get-caller-identity
echo "---------------------"
echo "---------------------"
echo "---------------------Access folder: CD \API_Helpers---------------------"
cd $DEFAULT_PATH/$CUSTOMIZATION/api_helpers/
echo "---------------------Done!---------------------"
echo "---------------------"
echo "---------------------"

if [[ -z "$has_parameter_store" ]]; then
    echo "---------------------Executing ./get_cidr.py---------------------"
    cidr=$(python3 ./get_cidr.py $accountnumber $accountName $regionCidr $ipamApiGtw $ipamLambda)
    echo "---------------------Done!---------------------"
    echo "---------------------"
    echo "---------------------"
    echo "---------------------Show CIDR before convertion---------------------"
    echo $cidr
    echo "---------------------"
    echo "---------------------"
    echo "---------------------Convert CIDR string---------------------"
    IFS='""'
    read -ra ARR <<< "$cidr"
    cidr="${ARR[3]}"
    echo "---------------------Done!---------------------"
    echo "---------------------"
    echo "---------------------"
    echo "---------------------Show CIDR after convertion---------------------"
    echo $cidr
    echo "---------------------"
    echo "---------------------"
    echo "---------------------"
    echo "---------------------"
    echo "---------------------Change AWS_PROFILE=AFT-TARGET-admin---------------------"
    export AWS_PROFILE=aft-target
    echo "aws sts get-caller-identity"
    aws sts get-caller-identity
    echo "aws sts get-caller-identity"
    echo "---------------------"
    echo "---------------------"
    echo "---------------------Creating CIDR parameter store---------------------"
    aws ssm put-parameter --name "/$accountnumber/vpc/cidr" --value "$cidr" --type "String" --overwrite
    echo "---------------------Done!---------------------"
    echo "---------------------"
    echo "---------------------"
else
    echo "SSM parameter store for CIDR already exists, no need for a new creation."   
fi

echo "---------------------Change AWS_PROFILE=AFT-TARGET-admin---------------------"
export AWS_PROFILE=aft-management
echo "---------------------aws sts get-caller-identity---------------------"
aws sts get-caller-identity
echo $accountnumber > prd.txt
aftnumber=$(aws sts get-caller-identity --query Account --output text)
aws s3 cp prd.txt s3://aft-backend-$aftnumber-primary-region/account-number-pipeline/prd.txt