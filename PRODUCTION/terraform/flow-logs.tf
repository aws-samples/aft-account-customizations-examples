resource "aws_kms_key" "flow_log" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 10
  policy                  = <<EOF
{
    "Id": "key_policy",
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Enable IAM User Permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "logs.${local.region}.amazonaws.com"
            },
            "Action": [
                "kms:Encrypt*",
                "kms:Decrypt*",
                "kms:ReEncrypt*",
                "kms:GenerateDataKey*",
                "kms:Describe*"
            ],
            "Resource": "*",
            "Condition": {
                "ArnEquals": {
                    "kms:EncryptionContext:aws:logs:arn": "arn:aws:logs:${local.region}:${data.aws_caller_identity.current.account_id}:log-group:*"
                }
            }
        }
    ]
}
EOF

  enable_key_rotation = true
}

resource "aws_iam_role" "vpc_flow_log_cloudwatch" {

  name_prefix          = "vpc-flow-log-role-"
  assume_role_policy   = data.aws_iam_policy_document.flow_log_cloudwatch_assume_role.json

}

data "aws_iam_policy_document" "flow_log_cloudwatch_assume_role" {

  statement {
    sid = "AWSVPCFlowLogsAssumeRole"

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }

    effect = "Allow"

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "vpc_flow_log_cloudwatch" {
  role       = aws_iam_role.vpc_flow_log_cloudwatch.name
  policy_arn = aws_iam_policy.vpc_flow_log_cloudwatch.arn
}

resource "aws_iam_policy" "vpc_flow_log_cloudwatch" {
  name_prefix = "vpc-flow-log-to-cloudwatch-"
  policy      = data.aws_iam_policy_document.vpc_flow_log_cloudwatch.json
}

data "aws_iam_policy_document" "vpc_flow_log_cloudwatch" {

  statement {
    sid = "AWSVPCFlowLogsPushToCloudWatch"

    effect = "Allow"

    actions = [
        "logs:PutLogEvents"
    ]

    resources = [
      "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:*:log-stream:*"
    ]
  }

  statement {
    sid = "AWSVPCFlowLogsPushToCloudWatch1"

    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]

    resources = [
      "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:*"
    ]
  }

}

resource "aws_cloudwatch_log_group" "flow_log" {
    #checkov:skip=CKV_AWS_338: No need, logs in centralized account.
  name              = "log-group-${data.aws_ssm_parameter.project.value}-prod"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.flow_log.arn
}

resource "aws_flow_log" "prod" {
  iam_role_arn    = aws_iam_role.vpc_flow_log_cloudwatch.arn
  log_destination = aws_cloudwatch_log_group.flow_log.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.vpc.id
}