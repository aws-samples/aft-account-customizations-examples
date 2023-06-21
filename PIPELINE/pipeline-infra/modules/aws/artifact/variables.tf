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