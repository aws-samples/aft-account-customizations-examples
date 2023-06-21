resource "aws_s3_bucket" "artifact" {
  #checkov:skip=CKV_AWS_144 - No needed cross-region replication enabled
  #checkov:skip=CKV_AWS_21 - No needed versioning enabled
  #checkov:skip=CKV_AWS_18 - No needed access log enabled
  #checkov:skip=CKV2_AWS_61 - No needed lifecycle configuration
  #checkov:skip=CKV2_AWS_62 - No needed notification
  bucket = "${data.aws_caller_identity.current.account_id}-${var.application_name}-${var.environment}"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifact" {
  bucket = aws_s3_bucket.artifact.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.artifact.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "artifact" {
  bucket = aws_s3_bucket.artifact.id
  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_object" "object" {
  #checkov:skip=CKV_AWS_186 - Bucket encryption enabled
  bucket = aws_s3_bucket.artifact.bucket
  key    = "dynamic-submodule/SubModule.sh"
  source = "./dynamic-submodule/SubModule.sh"
  etag = filemd5("./dynamic-submodule/SubModule.sh")
}


output "artifact_bucket" {
  value = aws_s3_bucket.artifact.arn
}

output "artifact_bucket_name" {
  value = aws_s3_bucket.artifact.bucket
}
