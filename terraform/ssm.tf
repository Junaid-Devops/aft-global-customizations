resource "aws_ssm_parameter" "AWSAccount" {
  name  = "/aws/AWSAccount"
  type  = "String"
  value = data.aws_caller_identity.current.account_id
}