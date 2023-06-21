resource "aws_codepipeline" "pipeline" {
  name     = "pipeline-iac-${var.application_name}-${var.environment}"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = var.artifact_bucket_name
    type     = "S3"

    encryption_key {
      id   = var.artifact_kms
      type = "KMS"
    }
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source_artifact"]
      configuration = {
        RepositoryName       = var.source_repository_name
        BranchName           = var.source_branch_name
        PollForSourceChanges = true
        OutputArtifactFormat = "CODEBUILD_CLONE_REF"
      }
      role_arn = aws_iam_role.codepipeline_action_source.arn
    }
  }

  stage {
    name = "CheckIAC-and-PlanFMT"

    action {
      name            = "CheckIAC"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_artifact"]
      version         = "1"
      configuration = {
        ProjectName = var.check_project
      }
      role_arn = aws_iam_role.codepipeline_action_plan_fmt.arn
    }

    action {
      name            = "TerraformPlanAndFmt"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_artifact"]
      output_artifacts = ["plan"]
      version         = "1"
      configuration = {
        ProjectName = var.plan_project
      }
      role_arn = aws_iam_role.codepipeline_action_plan_fmt.arn
    }

  }


  stage {
    name = "Approval"

    action {
      name     = "Approval"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"

      configuration = {
        NotificationArn = aws_sns_topic.approval.arn
        CustomData = var.approve_comment
      }
      role_arn = aws_iam_role.codepipeline_action_apply.arn
    }
  }

  stage {
    name = "Apply"

    action {
      name            = "TerraformApply"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["plan"]
      version         = "1"

      configuration = {
        ProjectName = var.apply_project
      }
      role_arn = aws_iam_role.codepipeline_action_apply.arn
    }
  }
}