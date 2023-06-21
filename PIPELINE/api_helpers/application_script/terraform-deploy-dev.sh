#!/bin/bash
echo "---------------------Get Child Account Number---------------------"
export AWS_PROFILE=aft-target
echo "aws sts get-caller-identity"
aws sts get-caller-identity
accountnumber=$(aws sts get-caller-identity --query Account --output text)
echo $accountnumber

echo "---------------------Extrai SSM Paremeter Store JINJA de DEV  Da Conta AFT---------------------"
export AWS_PROFILE=aft-management
aws sts get-caller-identity
jinja_parameters=`aws ssm get-parameter --name "/dev/terraform-parameters/jinja"  --query Parameter.Value --output text`

echo "---------------------Tratamento do JSON---------------------"
export environment=`echo $jinja_parameters | jq -r '.environment'`
export workloadAccount=`echo $jinja_parameters | jq -r '.workloadAccount'`
echo "environment=$environment"
echo "workloadAccount=$workloadAccount"
echo "---------------------Jinja template apply na pasta environments/dev---------------------"
cd $DEFAULT_PATH/$CUSTOMIZATION/pipeline-infra/environments/dev/

export AWS_PROFILE=aft-target
echo "aws sts get-caller-identity"
aws sts get-caller-identity
projectName=`aws ssm get-parameter --name "/aft/account-request/custom-fields/project"  --query Parameter.Value --output text`
rm -rf dev.tfvars
for f in *.jinja; do jinja2 $f -D pipelineAccount=$accountnumber -D provider_region=$CT_MGMT_REGION  -D workloadAccount=$workloadAccount -D projectName=$projectName  -D environment=$environment>> ./$(basename $f .jinja).tfvars; done
cat dev.tfvars
echo "---------------------CD to pipeline-infra root folder---------------------"
cd $DEFAULT_PATH/$CUSTOMIZATION/pipeline-infra/
echo $PWD
echo "---------------------Acessando conta Pipeline---------------------"
export AWS_PROFILE=aft-target
echo "aws sts get-caller-identity"
aws sts get-caller-identity

echo "---------------------Terraform init---------------------"
echo "---------------------Trying to terraform init the Pipeline-Infra @PipelineAccount to create pipeline @DevAccount!---------------------"
TFSTATE_BUCKET="backend-terraform-pipeline-$accountnumber"
TFSTATE_KEY="pipeline/dev/terraform.tfstate"
TFSTATE_REGION="$CT_MGMT_REGION"
echo "TFSTATE_BUCKET=$TFSTATE_BUCKET"
echo "TFSTATE_KEY=$TFSTATE_KEY"
echo "TFSTATE_REGION=$TFSTATE_REGION"

terraform init -reconfigure \
-backend-config="bucket=$TFSTATE_BUCKET" \
-backend-config="key=$TFSTATE_KEY" \
-backend-config="profile=aft-target" \
-backend-config="region=$TFSTATE_REGION" 

echo "---------------------Terraform apply for module.state---------------------"
terraform plan -target="module.state" -var-file=environments/dev/dev.tfvars -out state-dev.tfplan
terraform apply "state-dev.tfplan"

echo "---------------------Terraform apply for module.artifact---------------------"
terraform plan -target="module.artifact" -target="module.codeBuild" -target="module.pipeline" -var-file=environments/dev/dev.tfvars -out state-dev.tfplan
terraform apply "state-dev.tfplan"