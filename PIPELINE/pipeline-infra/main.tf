data "aws_caller_identity" "current" {}

terraform {
  backend "s3" {}
}

module "state" {
  source      = "./modules/aws/state"
  aws_region       = var.aws_region
  application_name = var.application_name
  environment      = var.environment
}

module "artifact" {
  source      = "./modules/aws/artifact"
  aws_region       = var.aws_region
  application_name = var.application_name
  environment      = var.environment
}

module "codeBuild" {
  source                    = "./modules/aws/codeBuild"
  providers = {
  aws.workload   = aws.workload
}
  aws_region                = var.aws_region
  application_name          = var.application_name
  environment               = var.environment
  terraform_path            = var.terraform_path
  backend_s3_arn            = "arn:aws:s3:::${data.aws_caller_identity.current.account_id}-${var.application_name}-tfstate"
  backend_lock_dynamodb_arn = "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${data.aws_caller_identity.current.account_id}-${var.application_name}-tflock"
  artifact_s3               = module.artifact.artifact_bucket
  artifact_kms              = module.artifact.artifact_kms
  workloadAccount           = var.workloadAccount
  source_branch_name        = var.source_branch_name
  workspace                 = var.environment
  artifact_bucket_name      = module.artifact.artifact_bucket_name

}

module "pipeline" {
  source                    = "./modules/aws/pipeline"
  aws_region                = var.aws_region
  application_name          = var.application_name
  environment               = var.environment
  artifact_s3               = module.artifact.artifact_bucket
  artifact_kms              = module.artifact.artifact_kms
  apply_project             = module.codeBuild.apply_project
  plan_project              = module.codeBuild.plan_project
  check_project             = module.codeBuild.check_project
  subModules_project        = module.codeBuild.subModules_project
  source_branch_name        = var.source_branch_name
  source_repository_arn     = var.source_repository_arn
  source_repository_name    = var.source_repository_name
  artifact_bucket_name      = module.artifact.artifact_bucket_name
  approve_comment           = var.approve_comment
}