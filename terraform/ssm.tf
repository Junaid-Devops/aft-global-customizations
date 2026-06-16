# Default Provider: This acts inside the TARGET vended account
provider "aws" {
  region = "us-east-1"
  # (AFT automatically handles the assume_role configuration here behind the scenes)
}

# Secondary Provider: Explicitly targets the MANAGEMENT account
# We use an alias so we can reference it when needed
provider "aws" {
  alias  = "management"
  region = "us-east-1" 
  # If TFC runs with management credentials initially, it uses them here directly
}

# ====================================================================
# THE DATA LOOKUP (Reaches into Management Account)
# ====================================================================
data "aws_dynamodb_table_item" "aft_metadata" {
  provider   = aws.management # <-- CRITICAL: Tells TF to look in the Management Account!
  table_name = "aft-request-metadata"
  
  key = jsonencode({
    "id" = { "S" = data.aws_caller_identity.current.account_id }
  })
}

# ====================================================================
# THE SSM PARAMETERS (Deploys into the Target Vended Account)
# ====================================================================
data "aws_caller_identity" "current" {} # Uses default provider (Target Account)

locals {
  parsed_item  = jsondecode(data.aws_dynamodb_table_item.aft_metadata.item)
  account_name = local.parsed_item.account_name.S
}

resource "aws_ssm_parameter" "AWSAccountID" {
  # No provider specified = Uses default provider (Target Account)
  name      = "/aft/AWSAccountID"
  type      = "String"
  value     = data.aws_caller_identity.current.account_id
  overwrite = true
}

resource "aws_ssm_parameter" "AWSAccountName" {
  # No provider specified = Uses default provider (Target Account)
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