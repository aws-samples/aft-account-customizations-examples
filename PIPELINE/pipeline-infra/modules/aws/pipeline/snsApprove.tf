resource "aws_sns_topic" "approval" {
  name = "approval-${var.application_name}-${var.environment}"
  kms_master_key_id = "alias/aws/sns"
}