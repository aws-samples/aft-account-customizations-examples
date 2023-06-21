data "aws_caller_identity" "current" {}

# ------------------------------------------------------------
# STS Assume Cross Account Role
# ------------------------------------------------------------
resource "aws_iam_policy" "sts_cross" {
  name        = "${var.application_name}-stsAssume-InfraBuildRole-${var.environment}"
  description = "Allow CodeBuild assume cross account role"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "STSCrossAccount"
        Action = [
          "sts:AssumeRole"
        ]
        Effect   = "Allow"
        Resource = [
                      "arn:aws:iam::${var.workloadAccount}:role/InfraBuildRole-${var.application_name}"             
                  ]
      }
    ]
  })
}


# ------------------------------------------------------------
# IAM Apply
# ------------------------------------------------------------
resource "aws_iam_role" "codebuild_project_apply" {
  name = "${var.application_name}-TerraformCodeBuildProjectApplyRole-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
        Effect = "Allow"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_project_apply_power_user" {
  role       = aws_iam_role.codebuild_project_apply.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

resource "aws_iam_role_policy_attachment" "codebuild_project_apply_iam_full_access" {
  #checkov:skip=CKV2_AWS_56 - Pipeline Access to create resources in workload account
  role       = aws_iam_role.codebuild_project_apply.name
  policy_arn = "arn:aws:iam::aws:policy/IAMFullAccess"
}

resource "aws_iam_role_policy_attachment" "codebuild_project_apply_sts" {
  role       = aws_iam_role.codebuild_project_apply.name
  policy_arn = aws_iam_policy.sts_cross.arn
}

resource "aws_iam_role" "codebuild_project_plan_fmt" {
  name = "${var.application_name}-TerraformCodeBuildProjectPlanFmtRole-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
        Effect = "Allow"
      },
    ]
  })
}

# ------------------------------------------------------------
# IAM Plan
# ------------------------------------------------------------
resource "aws_iam_policy" "codebuild_project_plan_fmt" {
  name        = "${var.application_name}-TerraformCodeBuildActionPlanAndFmtPolicy-${var.environment}"
  description = "Allow CodeBuild to access to CloudWatch, Artifact store and backend"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AllowWriteLogToCloudWatchLogs"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = ["*"]
      },
      {
        Sid = "AllowArtifactStoreAccess"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
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
      },
      {
        Sid = "AllowListBackendS3"
        Action = [
          "s3:ListBucket",
        ]
        Effect   = "Allow"
        Resource = var.backend_s3_arn
      },
      {
        Sid = "AllowAccessToBackendS3"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
        ]
        Effect   = "Allow"
        Resource = "${var.backend_s3_arn}/*"
      },
      {
        Sid = "AllowAccessToBackendDynamoDBLockTable"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Effect   = "Allow"
        Resource = var.backend_lock_dynamodb_arn
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_project_plan_fmt" {
  role       = aws_iam_role.codebuild_project_plan_fmt.name
  policy_arn = aws_iam_policy.codebuild_project_plan_fmt.arn
}

resource "aws_iam_role_policy_attachment" "codebuild_project_plan_fmt_read_only" {
  role       = aws_iam_role.codebuild_project_plan_fmt.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "codebuild_project_plan_sts" {
  role       = aws_iam_role.codebuild_project_plan_fmt.name
  policy_arn = aws_iam_policy.sts_cross.arn
}


# ------------------------------------------------------------
# IAM Cross-Account
# ------------------------------------------------------------
provider "aws" {
  alias = "workload"
}

resource "aws_iam_role" "infra_build_workload" {
  name = "InfraBuildRole-${var.application_name}"
  provider = aws.workload
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Effect = "Allow"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "infra_build_workload" {
  #checkov:skip=CKV_AWS_274 - Pipeline Access to create resources in workload account
  provider = aws.workload
  role       = aws_iam_role.infra_build_workload.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}