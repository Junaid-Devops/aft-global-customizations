# ====================================================================
# 1. MANAGEMENT PROVIDER (Assuming the active Execution Role)
# ====================================================================
provider "aws" {
  alias  = "management"
  region = "us-east-1" 
  
  assume_role {
    role_arn = "arn:aws:iam::678780124859:role/AWSAFTExecution"
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

# Automatically uses the default provider from AFT (Target Vended Account)
data "aws_caller_identity" "current" {} 

# ====================================================================
# 3. DYNAMIC DATA PARSING
# ====================================================================
locals {
  parsed_item   = jsondecode(data.aws_dynamodb_table_item.aft_metadata.item)
  account_name  = local.parsed_item.account_name.S
  abc_division  = local.parsed_item.account_level_tags["ABC:Division"].S
}

# ====================================================================
# 4. TARGET ACCOUNT SSM PARAMETERS
# ====================================================================

resource "aws_ssm_parameter" "AWSAccountID" {
  name  = "/aft/AWSAccountID"
  type  = "String"
  value = data.aws_caller_identity.current.account_id
  # Removed overwrite = true to clear the API tagging race condition
}

# (This one already succeeded, keeping it exactly the same)
resource "aws_ssm_parameter" "AWSAccountName" {
  name  = "/aft/AWSAccountName"
  type  = "String"
  value = local.account_name
}

resource "aws_ssm_parameter" "ABCDivision" {
  name  = "/aft/team"
  type  = "String"
  value = local.team
}
