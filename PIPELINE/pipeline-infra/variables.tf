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

variable "workloadAccess" {
  description = ""
  type = string
}

#codeBuild

variable "terraform_path" {
    description = "Path where the terraform code is located"
    type = string
}

variable "workloadAccount" {
  description = "Workload Account ID"
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


variable "approve_comment" {
    description = "comment that will go in the approval email"
    type = string
}