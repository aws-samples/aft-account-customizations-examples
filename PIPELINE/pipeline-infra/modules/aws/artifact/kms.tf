data "aws_caller_identity" "current" {}
resource "aws_kms_key" "artifact" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 10
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "*"
        Resource = "*"
      },
    ]
  })

  enable_key_rotation = true
}

resource "aws_kms_alias" "artifact" {
  name          = "alias/${var.environment}/CodeArtifactKey"
  target_key_id = aws_kms_key.artifact.key_id
}

output "artifact_kms" {
  value = aws_kms_key.artifact.arn
}