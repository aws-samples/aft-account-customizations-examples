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

#pipeline

variable "source_repository_name" {
    description = "Repository name where terraform code is located"
    type = string
}

variable "source_branch_name" {
    description = "Name of the branch where the pipeline will be listening"
    type = string
}

variable "source_repository_arn" {
    description = "ARN where terraform code is located"
    type = string
}

variable "subModules_project" {
  description = ""
  type        = string
}

variable "check_project" {
  description = ""
  type        = string
}

variable "plan_project" {
  description = ""
  type        = string
}

variable "apply_project" {
  description = ""
  type        = string
}

variable "artifact_s3" {
  description = ""
  type        = string
}

variable "artifact_kms" {
  description = ""
  type        = string
}

variable "artifact_bucket_name" {
    description = ""
    type = string
}


variable "approve_comment" {
    description = "comment that will go in the approval email"
    type = string
}