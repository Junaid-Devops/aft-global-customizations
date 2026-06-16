# ====================================================================
# 1. MANAGEMENT PROVIDER WITH EXPLICIT ROLE ASSUMPTION
# ====================================================================
provider "aws" {
  alias  = "management"
  region = "us-east-1" 
  
  # Crucial: Force the management provider to assume the designated AFT Admin role
  # if your ssm.tf is handled by Jinja, use: role_arn = "{{ aft_admin_role_arn }}"
  assume_role {
    role_arn = "arn:aws:iam::678780124859:role/AWSAFTAdmin" 
  }
}

# ====================================================================
# 2. DATA LOOKUPS
# ====================================================================
# Reaches into the Management Account's DynamoDB Table
data "aws_dynamodb_table_item" "aft_metadata" {
  provider   = aws.management 
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