# ------------------------------------------------------------
# CodeBuild Check IAC
# ------------------------------------------------------------
resource "aws_codebuild_project" "plan_check" {
  #checkov:skip=CKV_AWS_314 - No need
  name         = "${var.application_name}-TerraformCheckIAC-${var.environment}"
  description  = "Project to execute terraform plan"
  service_role = aws_iam_role.codebuild_project_plan_fmt.arn
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
    buildspec = templatefile("${path.module}/buildspecActionPlanCheckIAC.yml", {
      TERRAFORM_PATH = var.terraform_path,
    })
  }
}

output "check_project" {
  value = aws_codebuild_project.plan_check.name
}