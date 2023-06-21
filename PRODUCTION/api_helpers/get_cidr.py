#!/usr/bin/python
# Copyright Amazon.com, Inc. or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
import boto3
import json
import sys

account_number = sys.argv[1]
account_name = sys.argv[2]
region = sys.argv[3]
ipamapigtw = sys.argv[4]
ipamlambda = sys.argv[5]
lambda_client = boto3.client('lambda')
params = {  "RequestType": "Create",
            "ResourceProperties": {
                  "ApiRegion": region,        
                  "AccountId": account_number,
                  "Region": region ,          
                  "ProjectCode": account_name,
                  "Prefix": "22",
                  "Requestor": "aft-automation",
                  "Env": "prod",
                  "Reason": "Requesting a new CIDR Range",
                  "CidrApiEndpoint": ipamapigtw
              }
        }

response = lambda_client.invoke(
    FunctionName=ipamlambda,
    Payload=json.dumps(params),


)

print(response['Payload'].read().decode("utf-8"))
