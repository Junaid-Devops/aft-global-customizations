# ====================================================================
# 1. MANAGEMENT PROVIDER ONLY (The default one is already in aft-providers.tf)
# ====================================================================
provider "aws" {
  alias  = "management"
  region = "us-east-1" 
}

# ====================================================================
# 2. DATA LOOKUPS
# ====================================================================
# Reaches into the Management Account's DynamoDB Table
data "aws_dynamodb_table_item" "aft_metadata" {
  provider   = aws.management # <-- Uses the management alias above
  table_name = "aft-request-metadata"
  
  key = jsonencode({
    "id" = { "S" = data.aws_caller_identity.current.account_id }
  })
}

# Automatically uses the default provider from aft-providers.tf (Target Account)
data "aws_caller_identity" "current" {} 

# ====================================================================
# 3. DYNAMIC DATA PARSING
# ====================================================================
locals {
  parsed_item  = jsondecode(data.aws_dynamodb_table_item.aft_metadata.item)
  account_name = local.parsed_item.account_name.S
}

# ====================================================================
# 4. TARGET ACCOUNT SSM PARAMETERS
# ====================================================================
# Both of these drop down to the default provider automatically,
# landing safely inside the Target Vended Account.

resource "aws_ssm_parameter" "AWSAccountID" {
  name      = "/aft/AWSAccountID"
  type      = "String"
  value     = data.aws_caller_identity.current.account_id
  overwrite = true
}

resource "aws_ssm_parameter" "AWSAccountName" {
  name      = "/aft/AWSAccountName"
  type      = "String"
  value     = local.account_name
  overwrite = true
}


# This will print the active IAM Role ARN in your TFC/CodeBuild logs
output "current_terraform_iam_identity" {
  value       = data.aws_caller_identity.current.arn
  description = "The exact IAM Role or User executing this Terraform plan"
}