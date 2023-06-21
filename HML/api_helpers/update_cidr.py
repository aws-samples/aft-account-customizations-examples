#!/usr/bin/python
# Copyright Amazon.com, Inc. or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
import boto3
import json
import sys

ipamlambda = sys.argv[5]
ipamapigtw = sys.argv[4]
region = sys.argv[3]
cidr_block = sys.argv[2]
current_VPC_ID = sys.argv[1]  

lambda_client = boto3.client('lambda')
params = {
            "RequestType": "Create",
            "ResourceProperties": {
                  "ApiRegion": region,
                  "Cidr": cidr_block,
                  "VpcId": current_VPC_ID,
                  "CidrApiEndpoint": ipamapigtw

              }
         }

response = lambda_client.invoke(
    FunctionName=ipamlambda,
    Payload=json.dumps(params),
)

print(response['Payload'].read().decode("utf-8"))
