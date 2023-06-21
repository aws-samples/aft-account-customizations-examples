# ------------------------------------------------------------
# CodeBuild Apply
# ------------------------------------------------------------
resource "aws_codebuild_project" "apply" {
  #checkov:skip=CKV_AWS_314 - No need

  name         = "${var.application_name}-TerraformApply-${var.environment}"
  description  = "Project to execute terraform apply"
  service_role = aws_iam_role.codebuild_project_apply.arn
  encryption_key = var.artifact_kms

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "hashicorp/terraform:latest"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type = "CODEPIPELINE"
    buildspec = templatefile("${path.module}/buildspecActionApply.yml", {
      TERRAFORM_PATH = var.terraform_path,
      WORKSPACE      = var.workspace,
      ENV            = var.environment,
    })
  }
}

output "apply_project" {
  value = aws_codebuild_project.apply.name
}