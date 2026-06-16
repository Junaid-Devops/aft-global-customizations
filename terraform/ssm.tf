data "aws_caller_identity" "current" {}

resource "aws_ssm_parameter" "AWSAccount" {
  name  = "/aft/AWSAccount"
  type  = "String"
  value = data.aws_caller_identity.current.account_id
}


# This will print the active IAM Role ARN in your TFC/CodeBuild logs
output "current_terraform_iam_identity" {
  value       = data.aws_caller_identity.current.arn
  description = "The exact IAM Role or User executing this Terraform plan"
}