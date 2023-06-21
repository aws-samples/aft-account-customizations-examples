################################################################################
# CodeCommit Module
################################################################################
data "aws_ssm_parameter" "project" {
  name = "/aft/account-request/custom-fields/project"
}

resource "aws_codecommit_repository" "pipeline" {
  #checkov:skip=CKV2_AWS_37 - Pipeline that uses this repository already has the approval rules
  repository_name = "${data.aws_ssm_parameter.project.value}-IAC-Repository"
  description     = "This is the Pipeline Repository"
}

