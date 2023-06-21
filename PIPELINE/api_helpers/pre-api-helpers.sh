#!/bin/bash

echo "Executing Pre-API Helpers"
echo "---------------------"
echo "---------------------"
echo "---------------------printenv---------------------"
printenv
echo "---------------------Get Child Account Number---------------------"
accountnumber=$(aws sts get-caller-identity --query Account --output text)
echo $accountnumber
echo "---------------------"
echo "---------------------"
echo "---------------------Change AWS_PROFILE=SHARED-management-admin---------------------"
export AWS_PROFILE=aft-management
echo "aws sts get-caller-identity"
aws sts get-caller-identity
echo "---------------------"
echo "---------------------"
echo "---------------------Access folder: CD \API_Helpers---------------------"
cd $DEFAULT_PATH/$CUSTOMIZATION/api_helpers/
echo "---------------------Done!---------------------"
echo "---------------------"
echo "---------------------"
echo "---------------------Change AWS_PROFILE=aft-management-admin---------------------"
export AWS_PROFILE=aft-management-admin
echo "---------------------aws sts get-caller-identity---------------------"
aws sts get-caller-identity
echo "---------------------"
echo "---------------------"
echo "---------------------Download metadata from bucket---------------------"
aftnumber=$(aws sts get-caller-identity --query Account --output text)
aws s3 cp s3://aft-backend-$aftnumber-primary-region/account-number-pipeline/dev.txt dev.txt
aws s3 cp s3://aft-backend-$aftnumber-primary-region/account-number-pipeline/hml.txt hml.txt
aws s3 cp s3://aft-backend-$aftnumber-primary-region/account-number-pipeline/prd.txt prd.txt
dev_account=$(cat dev.txt)
hml_account=$(cat hml.txt)
prd_account=$(cat prd.txt)
echo "---------------------"
echo "---------------------"
echo "---------------------Creating Trust Policy to Pipeline Account have access to Workloads accounts---------------------"
echo '{' > Role-Trust-Policy.json
echo '    "Version": "2012-10-17",' >> Role-Trust-Policy.json
echo '    "Statement": [' >> Role-Trust-Policy.json
echo '        {' >> Role-Trust-Policy.json
echo '            "Effect": "Allow",' >> Role-Trust-Policy.json
echo '            "Principal": {' >> Role-Trust-Policy.json
echo '                "AWS": [' >> Role-Trust-Policy.json
echo '                    "arn:aws:sts::'$aftnumber':assumed-role/AWSAFTAdmin/AWSAFT-Session",' >> Role-Trust-Policy.json
echo '                    "arn:aws:sts::'$accountnumber':assumed-role/AWSAFTExecution/AWSAFT-Session"' >> Role-Trust-Policy.json
echo '                ]' >> Role-Trust-Policy.json
echo '            },' >> Role-Trust-Policy.json
echo '            "Action": "sts:AssumeRole"' >> Role-Trust-Policy.json
echo '        }' >> Role-Trust-Policy.json
echo '    ]' >> Role-Trust-Policy.json
echo '}' >> Role-Trust-Policy.json

echo "---------------------"
echo "---------------------"
echo "---------------------cat Role-Trust-Policy.json---------------------"
cat Role-Trust-Policy.json
echo "---------------------"
echo "---------------------"
echo "---------------------Creating AWS Profile for dev-account---------------------"
profile="dev-account"
CREDENTIALS=$(aws sts assume-role --role-arn "arn:aws:iam::$dev_account:role/AWSAFTExecution" --role-session-name "AWSAFT-Session")
echo $CREDENTIALS
aws_access_key_id="$(echo "${CREDENTIALS}" | jq --raw-output ".Credentials[\"AccessKeyId\"]")"
aws_secret_access_key="$(echo "${CREDENTIALS}" | jq --raw-output ".Credentials[\"SecretAccessKey\"]")"
aws_session_token="$(echo "${CREDENTIALS}" | jq --raw-output ".Credentials[\"SessionToken\"]")"

aws configure set aws_access_key_id "${aws_access_key_id}" --profile "${profile}"
aws configure set aws_secret_access_key "${aws_secret_access_key}" --profile "${profile}"
aws configure set aws_session_token "${aws_session_token}" --profile "${profile}"

echo "---------------------Update assume role policy for dev-account---------------------"
aws iam update-assume-role-policy --role-name AWSAFTExecution --policy-document file://Role-Trust-Policy.json --profile ${profile}



echo "---------------------Change AWS_PROFILE=aft-management-admin---------------------"
export AWS_PROFILE=aft-management-admin
echo "---------------------aws sts get-caller-identity---------------------"
aws sts get-caller-identity

echo "---------------------"
echo "---------------------"
echo "---------------------Creating Trust Policy to Pipeline Account have access to Workloads accounts---------------------"

echo '{' > Role-Trust-Policy.json
echo '    "Version": "2012-10-17",' >> Role-Trust-Policy.json
echo '    "Statement": [' >> Role-Trust-Policy.json
echo '        {' >> Role-Trust-Policy.json
echo '            "Effect": "Allow",' >> Role-Trust-Policy.json
echo '            "Principal": {' >> Role-Trust-Policy.json
echo '                "AWS": [' >> Role-Trust-Policy.json
echo '                    "arn:aws:sts::'$aftnumber':assumed-role/AWSAFTAdmin/AWSAFT-Session",' >> Role-Trust-Policy.json
echo '                    "arn:aws:sts::'$accountnumber':assumed-role/AWSAFTExecution/AWSAFT-Session"' >> Role-Trust-Policy.json
echo '                ]' >> Role-Trust-Policy.json
echo '            },' >> Role-Trust-Policy.json
echo '            "Action": "sts:AssumeRole"' >> Role-Trust-Policy.json
echo '        }' >> Role-Trust-Policy.json
echo '    ]' >> Role-Trust-Policy.json
echo '}' >> Role-Trust-Policy.json

echo "---------------------"
echo "---------------------"
echo "---------------------cat Role-Trust-Policy.json---------------------"
cat Role-Trust-Policy.json

echo "---------------------"
echo "---------------------"
echo "---------------------Creating AWS Profile for hml-account---------------------"
profile="hml-account"
CREDENTIALS=$(aws sts assume-role --role-arn "arn:aws:iam::$hml_account:role/AWSAFTExecution" --role-session-name "AWSAFT-Session")
echo $CREDENTIALS
aws_access_key_id="$(echo "${CREDENTIALS}" | jq --raw-output ".Credentials[\"AccessKeyId\"]")"
aws_secret_access_key="$(echo "${CREDENTIALS}" | jq --raw-output ".Credentials[\"SecretAccessKey\"]")"
aws_session_token="$(echo "${CREDENTIALS}" | jq --raw-output ".Credentials[\"SessionToken\"]")"

echo $aws_access_key_id
echo $aws_secret_access_key
echo $aws_session_token
aws configure set aws_access_key_id "${aws_access_key_id}" --profile "${profile}"
aws configure set aws_secret_access_key "${aws_secret_access_key}" --profile "${profile}"
aws configure set aws_session_token "${aws_session_token}" --profile "${profile}"
echo "---------------------"
echo "---------------------"
echo "---------------------Update assume role policy for hml-account---------------------"
aws iam update-assume-role-policy --role-name AWSAFTExecution --policy-document file://Role-Trust-Policy.json --profile ${profile}

echo "---------------------"
echo "---------------------"
echo "---------------------Change AWS_PROFILE=aft-management-admin---------------------"
export AWS_PROFILE=aft-management-admin
echo "---------------------aws sts get-caller-identity---------------------"
aws sts get-caller-identity

echo "---------------------"
echo "---------------------"
echo "---------------------Creating Trust Policy to Pipeline Account have access to Workloads accounts---------------------"


echo '{' > Role-Trust-Policy.json
echo '    "Version": "2012-10-17",' >> Role-Trust-Policy.json
echo '    "Statement": [' >> Role-Trust-Policy.json
echo '        {' >> Role-Trust-Policy.json
echo '            "Effect": "Allow",' >> Role-Trust-Policy.json
echo '            "Principal": {' >> Role-Trust-Policy.json
echo '                "AWS": [' >> Role-Trust-Policy.json
echo '                    "arn:aws:sts::'$aftnumber':assumed-role/AWSAFTAdmin/AWSAFT-Session",' >> Role-Trust-Policy.json
echo '                    "arn:aws:sts::'$accountnumber':assumed-role/AWSAFTExecution/AWSAFT-Session"' >> Role-Trust-Policy.json
echo '                ]' >> Role-Trust-Policy.json
echo '            },' >> Role-Trust-Policy.json
echo '            "Action": "sts:AssumeRole"' >> Role-Trust-Policy.json
echo '        }' >> Role-Trust-Policy.json
echo '    ]' >> Role-Trust-Policy.json
echo '}' >> Role-Trust-Policy.json

echo "---------------------"
echo "---------------------"
echo "---------------------cat Role-Trust-Policy.json---------------------"
cat Role-Trust-Policy.json

echo "---------------------"
echo "---------------------"
echo "---------------------Creating AWS Profile for prd-account---------------------"
profile="prd-account"
CREDENTIALS=$(aws sts assume-role --role-arn "arn:aws:iam::$prd_account:role/AWSAFTExecution" --role-session-name "AWSAFT-Session")
echo $CREDENTIALS
aws_access_key_id="$(echo "${CREDENTIALS}" | jq --raw-output ".Credentials[\"AccessKeyId\"]")"
aws_secret_access_key="$(echo "${CREDENTIALS}" | jq --raw-output ".Credentials[\"SecretAccessKey\"]")"
aws_session_token="$(echo "${CREDENTIALS}" | jq --raw-output ".Credentials[\"SessionToken\"]")"

echo $aws_access_key_id
echo $aws_secret_access_key
echo $aws_session_token
aws configure set aws_access_key_id "${aws_access_key_id}" --profile "${profile}"
aws configure set aws_secret_access_key "${aws_secret_access_key}" --profile "${profile}"
aws configure set aws_session_token "${aws_session_token}" --profile "${profile}"

echo "---------------------"
echo "---------------------"
echo "---------------------Update assume role policy for prd-account---------------------"
aws iam update-assume-role-policy --role-name AWSAFTExecution --policy-document file://Role-Trust-Policy.json --profile ${profile}