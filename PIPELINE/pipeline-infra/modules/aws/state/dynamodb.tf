resource "aws_dynamodb_table" "state_locking" {
  #checkov:skip=CKV_AWS_119 - No needed Customer Managed CMK
  hash_key = "LockID"
  name     = "${data.aws_caller_identity.current.account_id}-${var.application_name}-tflock"
  server_side_encryption {
    enabled = true
  }
  point_in_time_recovery {
    enabled = true
  }
  attribute {
    name = "LockID"
    type = "S"
  }
  billing_mode = "PAY_PER_REQUEST"
}


output "lock_dynamo" {
  value = aws_dynamodb_table.state_locking.arn
}
