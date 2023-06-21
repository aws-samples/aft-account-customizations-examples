data "aws_caller_identity" "current" {}
# ------------------------------------------------------------
# IAM Role - CodePipeline Service role
# ------------------------------------------------------------
resource "aws_iam_role" "codepipeline" {
  name = "${var.application_name}-TerraformCodePipelineRole-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
        Effect = "Allow"
      },
    ]
  })
}

resource "aws_iam_policy" "codepipeline" {
  name        = "${var.application_name}-TerraformCodePipelinePolicy-${var.environment}"
  description = "Allow CodePipeline to access to CodeCommit, Artifact store and assume IAM roles declared at each action"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AllowAssumeRole"
        Action = [
          "sts:AssumeRole"
        ]
        Effect = "Allow"
        Resource = [
          aws_iam_role.codepipeline_action_source.arn,
          aws_iam_role.codepipeline_action_plan_fmt.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline" {
  role       = aws_iam_role.codepipeline.name
  policy_arn = aws_iam_policy.codepipeline.arn
}

# ------------------------------------------------------------
# IAM Role - CodePipeline Action role: Source
# ------------------------------------------------------------
resource "aws_iam_role" "codepipeline_action_source" {
  name = "${var.application_name}-TerraformCodePipelineActionSourceRole-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          AWS = aws_iam_role.codepipeline.arn
        }
        Effect = "Allow"
      },
    ]
  })
}

resource "aws_iam_policy" "codepipeline_action_source" {
  name        = "${var.application_name}-TerraformCodePipelineActionSourcePolicy-${var.environment}"
  description = "Allow CodePipeline to access to CodeCommit and Artifact store"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AllowCodeCommitAccess"
        Action = [
          "codecommit:GetBranch",
          "codecommit:GetRepository",
          "codecommit:GetCommit",
          "codecommit:GetUploadArchiveStatus",
          "codecommit:UploadArchive",
          "codecommit:CancelUploadArchive"
        ]
        Effect = "Allow"
        Resource = [
          var.source_repository_arn
        ]
      },
      {
        Sid = "AllowArtifactStoreAccess"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
        ]
        Effect = "Allow"
        Resource = [
          "${var.artifact_s3}/*",
        ]
      },
      {
        Sid = "AllowUseKMSKey"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDatakey*"
        ]
        Effect   = "Allow"
        Resource = var.artifact_kms
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline_action_source" {
  role       = aws_iam_role.codepipeline_action_source.name
  policy_arn = aws_iam_policy.codepipeline_action_source.arn
}

# ------------------------------------------------------------
# IAM Role - CodePipeline Action role: PlanAndFmt
# ------------------------------------------------------------
resource "aws_iam_role" "codepipeline_action_plan_fmt" {
  name = "${var.application_name}-TerraformCodePipelineActionPlanAndFmtRole-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          AWS = aws_iam_role.codepipeline.arn
        }
        Effect = "Allow"
      },
    ]
  })
}

resource "aws_iam_policy" "codepipeline_action_plan_fmt" {
  name        = "${var.application_name}-TerraformCodePipelineActionPlanAndFmtPolicy-${var.environment}"
  description = "Allow CodePipeline to start or stop codebuild"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AllowCodeBuildAccess"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild",
          "codebuild:StopBuild"
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:codebuild:${var.aws_region}:${data.aws_caller_identity.current.account_id}:project/${var.application_name}-TerraformPlanFmt-${var.environment}",
          "arn:aws:codebuild:${var.aws_region}:${data.aws_caller_identity.current.account_id}:project/${var.application_name}-TerraformCheckIAC-${var.environment}",
          "arn:aws:codebuild:${var.aws_region}:${data.aws_caller_identity.current.account_id}:project/${var.application_name}-TerraformApply-${var.environment}"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline_action_plan_fmt" {
  role       = aws_iam_role.codepipeline_action_plan_fmt.name
  policy_arn = aws_iam_policy.codepipeline_action_plan_fmt.arn
}

# ------------------------------------------------------------
# IAM Role - CodePipeline Action role: Apply
# ------------------------------------------------------------
resource "aws_iam_role" "codepipeline_action_apply" {
  name = "${var.application_name}-TerraformCodePipelineActionApplyRole-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          AWS = aws_iam_role.codepipeline.arn
        }
        Effect = "Allow"
      }
    ]
  })
}

resource "aws_iam_policy" "codepipeline_action_apply" {
  name        = "${var.application_name}-TerraformCodePipelineActionApplyPolicy-${var.environment}"
  description = "Allow CodePipeline to start or stop codebuild"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AllowCodeBuildAccess"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild",
          "codebuild:StopBuild"
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:codebuild:${var.aws_region}:${data.aws_caller_identity.current.account_id}:project/${var.application_name}-TerraformPlanFmt-${var.environment}",
          "arn:aws:codebuild:${var.aws_region}:${data.aws_caller_identity.current.account_id}:project/${var.application_name}-TerraformCheckIAC-${var.environment}",
          "arn:aws:codebuild:${var.aws_region}:${data.aws_caller_identity.current.account_id}:project/${var.application_name}-TerraformApply-${var.environment}"
        ]
      },
      {
        Sid = "AllowSendNotification"
        Action = [
          "sns:Publish"
        ]
        Effect = "Allow"
        Resource = aws_sns_topic.approval.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline_action_apply" {
  role       = aws_iam_role.codepipeline_action_apply.name
  policy_arn = aws_iam_policy.codepipeline_action_apply.arn
}