# aft-account-customizations-examples
This project contains a practical use case of the AFT account customizations logic. More details about the AFT see [AFT Doc](https://developer.hashicorp.com/terraform/tutorials/aws/aws-control-tower-aft)

## Background and solutions considerations
When working in multi-account scenarios it is quite common to come across the following situation:
- 3 Workload accounts (1 development account, 1 staging account and 1 production account)
- 1 Account for SLDC (Pipelines, Version Control and GITOPS)
   - In this type of account, cross-account access to the workload accounts is necessary so that the pipelines can deliver the codes in their respective environments

It turns out to be a challenge to manage the creation of these accounts in a standardized manner. Beyond this point, we have to think about managing the distribution of IPs so that the VPCs don't have ranges that conflict between them, which could cause future problems in case of need for a VPC Peering. Another challenge is automating all the manual steps that Setup requires.

Thinking about these challenges, an intelligence was developed using AFT Account Customizations that allows us to create workload accounts (dev, hml, prod) already with a VPC and its CIDR managed by the [CIDR MGMT](https://github.com/aws-samples/aws-vpc-cidr-mgmt) solution. In addition, intelligence allows the creation of a pipeline account already with a repository in the code commit and a pipeline (which delivers terraform codes) for each environment with cross-account roles for workload access.

# Solution overview

## Workload accounts (dev, hml e prod)

Workload accounts will have to customize the creation of the VPC following best practices and with its IP addressing managed by [CIDR MGMT](https://github.com/aws-samples/aws-vpc-cidr-mgmt).

### Getting CIDR available for use

in path "aft-account-customizations / account-type / api_helpers" there is the `pre-api-helpers.sh` script it will execute the following steps:
- Check if the account has already allocated an IP in **CIDR MGMT**, querying the AWS SSM Parameter Store with the name "/account-number/vpc/cidr" 
- If there is no CIDR allocated, Python `get_cidr.py` will be executed which will allocate it in **CIDR MGMT** and will record the Parameter Store with the allocated CIDR 

### VPC creation

In the path "aft-account-customizations / account-type / api_helpers / terraform" there is the VPC creation IAC that will do:
- Query the Parameter Store to retrieve the CIDR allocated to that account;
- Create the VPC according to the environment
   - Production → VPC with 3 public subnets and 3 private subnets with Nat Gateway in all 3 AZs;
   - Staging → VPC with 3 public subnets and 3 private subnets with Nat Gateway single AZ;
   - Development → VPC with 3 public subnets and 3 private subnets with Nat Gateway single AZ

### Updating CIDR MGMT with VPC ID

In the path "aft-account-customizations / account-type / api_helpers" there is the script `post-api-helpers.sh`, it will execute the following steps:
- Run Python `update_cidr.py` which will update the **CIDR MGMT** associating the VPC ID (created in the previous step) with the allocated CIDR

```
                          +-----------------+     
                          | SH              |   
                          | pre-api-helpers |   
                          +--------+--------+   
                                   |            
                                   |            
                          +--------+--------+   
                 +------->+ Parameter Store +
                 |        +--------+--------+    
                 |                 |             
                 |                 |             
                 |                 v             
                 |        +--------+--------+    
                 |       /                    \  
                 |      /                      \            +---------------+
              Get CIDR  | have allocated CIDR? |+---No----> +  get_cidr.py  +
                 |      \                      /            +---------------+
                 |       \                    /                     |
                 |        +-------------------+                     No
                 |                 |                                |
                 |                Yes                               v
                 |                 |                        +-----------------+       
                 |                 v                        + CIDR Management +
                 |        +------------------+              +-----------------+
                 x--------|    Terraform     |               
                          +------------------+
                                   |      
                                   | 
                                   v 
                          +------------------+
                          |       VPC        |
                          +------------------+


                          +------------------+         
                          | SH               |
                          | post-api-helpers |
                          +------------------+
                                   |
                                   | 
                                   v 
                          +------------------+            +-----------------+
                          +  update_cidr.py  +----------> + CIDR Management +
                          +------------------+            +-----------------+
```

## Pipeline Accounts

Pipeline accounts will be created with an AWS CodeCommit repository (to house the environment's IAC), an infrastructure pipeline for each environment (dev, hml, and prd), and cross-account roles for the pipeline to work properly.

## Creating cross-account roles

During the creation of workload accounts, a file was generated for each environment (dev, hml and prd) containing the respective account ID. These files are used in this customization step.

In the "aft-account-customizations / PIPELINE / api_helpers" folder there is the `pre-api-helpers.sh` script, it will perform the following steps:

- Will read the files with ID of Workload accounts

- For each Workload account:

   - The script will enter the workload account and change the trust policy of the role "AWSAFTExecution" allowing the pipeline account to assume

### AWS CodeCommit repository

In the path "aft-account-customizations / PIPELINE / api_helpers / terraform" there is the IAC for creating the CodeCommit repository, where the IAC for creating the project environment will be housed and in turn will sensitize the pipeline.

### IAC Pipeline Deployment

In the path "aft-account-customizations / PIPELINE / api_helpers" there is the script `post-api-helpers.sh`, it will perform the following steps:
- For each environment (dev, hml and prd):
   - Will populate the variables dynamically from the pipeline creation script using the Jinja tool (detailed below)
   - It will run the terraform script to create the pipeline according to the environment. In this step, the AWS CodeCommit repository will be linked (for the pipeline to make use of it) and the previously created cross-account access

## Jinja

Jinja is a fast, expressive, and extensible templating engine. Special placeholders in the template let you write code similar to Python syntax. Then the model receives data to render the final document. For more details check the product documentation.
Here, we are using Jinja to assemble Terraform's variables and backend files dynamically, allowing us to leave nothing hardcoded and the solution to be scalable.

In the "aft-account-customizations / account-type / api_helpers / terraform" folder there are *.jinja files where information is replaced dynamically and used during Terraform execution.

## Folder Structure
```
├── CODE_OF_CONDUCT.md
├── CONTRIBUTING.md
├── DEV
│   ├── api_helpers
│   │   ├── get_cidr.py
│   │   ├── post-api-helpers.sh
│   │   ├── pre-api-helpers.sh
│   │   ├── python
│   │   │   └── requirements.txt
│   │   └── update_cidr.py
│   └── terraform
│       ├── aft-providers.jinja
│       ├── backend.jinja
│       └── vpc.tf
├── HML
│   ├── api_helpers
│   │   ├── get_cidr.py
│   │   ├── post-api-helpers.sh
│   │   ├── pre-api-helpers.sh
│   │   ├── python
│   │   │   └── requirements.txt
│   │   └── update_cidr.py
│   └── terraform
│       ├── aft-providers.jinja
│       ├── backend.jinja
│       └── vpc.tf
├── LICENSE
├── PIPELINE
│   ├── api_helpers
│   │   ├── application_script
│   │   │   ├── terraform-deploy-dev.sh
│   │   │   ├── terraform-deploy-hml.sh
│   │   │   └── terraform-deploy-prd.sh
│   │   ├── post-api-helpers.sh
│   │   ├── pre-api-helpers.sh
│   │   └── python
│   │       └── requirements.txt
│   ├── pipeline-infra
│   │   ├── README.md
│   │   ├── environments
│   │   │   ├── dev
│   │   │   │   ├── dev.jinja
│   │   │   │   └── dev.tfbackend
│   │   │   ├── hml
│   │   │   │   ├── hml.jinja
│   │   │   │   └── hml.tfbackend
│   │   │   └── prd
│   │   │       ├── prd.jinja
│   │   │       └── prd.tfbackend
│   │   ├── main.tf
│   │   ├── modules
│   │   │   └── aws
│   │   │       ├── artifact
│   │   │       │   ├── kms.tf
│   │   │       │   ├── s3.tf
│   │   │       │   └── variables.tf
│   │   │       ├── codeBuild
│   │   │       │   ├── buildspecActionApply.yml
│   │   │       │   ├── buildspecActionPlanCheckIAC.yml
│   │   │       │   ├── buildspecActionPlanFmt.yml
│   │   │       │   ├── codebuildActionApply.tf
│   │   │       │   ├── codebuildActionCheckIAC.tf
│   │   │       │   ├── codebuildActionPlan.tf
│   │   │       │   ├── iam.tf
│   │   │       │   └── variables.tf
│   │   │       ├── pipeline
│   │   │       │   ├── codePipeline.tf
│   │   │       │   ├── iam.tf
│   │   │       │   ├── snsApprove.tf
│   │   │       │   └── variables.tf
│   │   │       └── state
│   │   │           ├── dynamodb.tf
│   │   │           ├── kms.tf
│   │   │           ├── s3.tf
│   │   │           └── variables.tf
│   │   ├── providers.tf
│   │   └── variables.tf
│   └── terraform
│       ├── aft-providers.jinja
│       ├── backend.jinja
│       ├── main.tf
│       ├── modules
│       │   └── vpc
│       │       ├── CHANGELOG.md
│       │       ├── LICENSE
│       │       ├── README.md
│       │       ├── UPGRADE-3.0.md
│       │       ├── main.tf
│       │       ├── modules
│       │       │   └── vpc-endpoints
│       │       │       ├── README.md
│       │       │       ├── main.tf
│       │       │       ├── outputs.tf
│       │       │       ├── variables.tf
│       │       │       └── versions.tf
│       │       ├── outputs.tf
│       │       ├── tobeerased
│       │       ├── variables.tf
│       │       ├── versions.tf
│       │       └── vpc-flow-logs.tf
│       ├── s3-tf-state.tf
│       ├── terraform.tfvars
│       └── variables.tf
├── PRODUCTION
│   ├── api_helpers
│   │   ├── get_cidr.py
│   │   ├── post-api-helpers.sh
│   │   ├── pre-api-helpers.sh
│   │   ├── python
│   │   │   └── requirements.txt
│   │   └── update_cidr.py
│   └── terraform
│       ├── aft-providers.jinja
│       ├── backend.jinja
│       └── vpc.tf
└── README.md

```
## Deployment

### To use this solution you must:
- AFT installed and configured [How to Install AFT](https://developer.hashicorp.com/terraform/tutorials/aws/aws-control-tower-aft)
- CIDR MGMT installed and configured (same region of AFT) [How to Install CIDR MGMT](https://github.com/aws-samples/aws-vpc-cidr-mgmt#deployment)

### Deploy
- Clone this repository
- Replace your AFT **aft-account-customizations** repository files with the files from this REPO

### Usage
- When creating an account with this scenario (dev, hml and prd), just inform the account type correctly in the **aft-account-request** file in the **account_customizations_name** field (the account type must be exactly the same as the folder name in **aft-account-customizations**)
- Inform the following parameters in the **aft-account-request** file **custom_fields** field
   - project = "project name" (will be concatenated to the resources name)
   - region = "region name"
   - ipamapigtw = "Execution URL of CIDR MGMT API Gateway" (Ex. "https://id-gateway.execute-api.us-west-2.amazonaws.com/v0/")
   - ipamlambda = "Name of the lambda created in the CIDR MGMT deployment"

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.

