provider "aws" {
  region = var.aws_region

}

provider "aws" {
  alias  = "workload"
  region = var.aws_region
  # profile  = var.workloadAccess
  assume_role {
    role_arn     = var.workloadAccess
    session_name = "AWSAFT-Session"
  }
}
