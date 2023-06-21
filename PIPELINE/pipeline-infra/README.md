# pipeline-infra

## Getting started

Project responsible for creating the CI/CD framework for Infrastructure as Code, using the Terraform language. In addition to integration and automatic depoy, security validations (static analysis) are performed using the tool [checkov](https://www.checkov.io/).

## Instructions

Run the code once for each environment.
For example: If you have a development, homolog and production environment. The code must be executed 3 times.

OBS: only the state module should be executed only once (in the first environment).

## Structure

The solution is composed of following modules:

- artifact
- codebuild
- pipeline
- state

The templates are organized in the following directories:

- **modules**: Contains the source code for each module
  - **<cloud_provider>**: Cloud provider specific directory
    - **artifact**: Source code for artifact module
      - Function: Create all resources for store artifacts.
    - **codebuild**: Source code for codebuild module
      - Function: Responsible for creating all codebuild resources necessary for build and deploy.
    - **pipeline**: Source code for pipeline module
      - Function: Create all pipeline orquestration.
    - **state**: Source code for state module
      - Function: Create resources for store Terraform State information

## Fill variables

In the [global.tfvars](./global.tfvars) file, the values for the variables needed to execute the code should be placed:

- **Global Variables**
  - aws_region: Region to be used
  - environment: Environment name ("dev", "hml", "prd")
  - application_name: Application name
  - workloadAccess: Profile that gives access to the workload account that will be deployed
- **codeBuild**
  - terraform_path: Path where the terraform code is located
  - workloadAccount: Workload Account ID
- **pipeline**
  - source_branch_name: Name of the branch where the pipeline will be listening
  - source_repository_arn: ARN where terraform code is located
  - source_repository_name: Repository name where terraform code is located
  - email: pipeline approver email
  - approve_comment: comment that will go in the approval email

---

## Deploy

Edit the [global.tfvars](./global.tfvars) file as per the guidelines above.

⚠️

> Run the following commands, if this is the first environment to be deployed in the pipeline:

```
terraform init
terraform plan -target="module.state" -var-file="global.tfvars"
terraform apply -target="module.state" -var-file="global.tfvars"

```

⭐

> For ALL environments: Run the following commands

```
terraform init
terraform plan -target="module.artifact" -target="module.codeBuild" -target="module.pipeline" -var-file="global.tfvars"
terraform apply -target="module.artifact" -target="module.codeBuild" -target="module.pipeline" -var-file="global.tfvars"

```

---

## Using the pipeline

⭐

> After pipeline creation
> In the project code (application infrastructure), edit the to put the backend information to use the S3 and DynamoDB created to control the terraform state. Example:

```
terraform {
  backend "s3" {
    bucket               = "<account-id>-<application-name>-tfstate"
    workspace_key_prefix = "appname"
    key                  = "terraform.tfstate"
    region               = "region"
    dynamodb_table       = "<account-id>-<application-name>-tflock"
  }
}

```

- Terraform Workspaces need to be created:
  - In the directory containing the Terraform code of the project (application infrastructure), execute the commands below:

```
terraform init
terraform workspace new dev
terraform workspace new hml
terraform workspace new prd
```

- In the project code (application infrastructure), variable files need to be in the following structure:

  - - **inventory**
      - **<environment_name>**
        - **global.tfvars**

## Issues

1. Windows users are having problem with stacksets instance. For Mac is working as intended.
   - https://github.com/hashicorp/terraform-provider-aws/issues/23349
2. 'arn:aws:s3:::lidiofflinetestes' resourcetaggingapi brings tags even when does not have tag

---

a
