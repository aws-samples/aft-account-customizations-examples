# Global Variables
variable "aws_region" {
  description = "AWS Region for deploying resources"
  type        = string
}

variable "environment" {
  description = "Lifecycle environment for deployment"
  type        = string
}
variable "application_name" {
  description = "Application hosted in this infrastructure"
  type        = string
}

variable "backend_s3_arn" {
  description = ""
  type        = string
}

variable "backend_lock_dynamodb_arn" {
  description = ""
  type        = string
}

variable "artifact_s3" {
  description = ""
  type        = string
}

variable "artifact_bucket_name" {
  description = ""
  type        = string
}

variable "artifact_kms" {
  description = ""
  type        = string
}

variable "source_branch_name" {
    description = ""
    type = string
}


variable "terraform_path" {
    description = "Path where the terraform code is located"
    type = string
}

variable "workloadAccount" {
  description = "Workload Account ID"
  type        = string
}

variable "workspace" {
  description = "Terraform Worspace name to be used"
  type        = string
}