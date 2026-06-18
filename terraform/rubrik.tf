# ====================================================================
# 1. DEFINE EXACT PROVIDER SOURCES
# ====================================================================
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    polaris = {
      source  = "rubrikinc/polaris"
      version = ">= 1.0.0"
    }
  }
}

# ====================================================================
# 2. POLARIS CONFIGURATION & MODULE
# ====================================================================
data "aws_ssm_parameter" "target_id" {
  name = "/aft/AWSAccountID"
  depends_on = [aws_ssm_parameter.AWSAccountID]
}

data "aws_ssm_parameter" "target_name" {
  name = "/aft/AWSAccountName"
  depends_on = [aws_ssm_parameter.AWSAccountName]
  
}

data "aws_secretsmanager_secret" "polaris_creds" {
  provider = aws.management
  name     = "Rubrik-AWS-Account"
}

data "aws_secretsmanager_secret_version" "polaris_creds_latest" {
  provider  = aws.management
  secret_id = data.aws_secretsmanager_secret.polaris_creds.id
}

provider "polaris" {
  credentials = data.aws_secretsmanager_secret_version.polaris_creds_latest.secret_string
}

module "cloud_native" {
  source = "rubrikinc/polaris-cloud-native/aws"

  aws_account_id   = data.aws_ssm_parameter.target_id.value
  aws_account_name = data.aws_ssm_parameter.target_name.value
  aws_regions      = ["us-west-2", "us-east-1", "us-east-2"]

  rsc_aws_features = [
   
    { name = "CLOUD_NATIVE_PROTECTION",          permission_groups = [] },
    { name = "CLOUD_DISCOVERY",          permission_groups = [] },
    { name = "CLOUD_NATIVE_S3_PROTECTION",       permission_groups = [] },
    { name = "CLOUD_NATIVE_DYNAMODB_PROTECTION", permission_groups = [] },
    { name = "RDS_PROTECTION",                   permission_groups = [] }
  ]
}

# ====================================================================
# 1. LOOK UP THE CENTRAL SHARED SERVICES HOST ID
# ====================================================================
data "polaris_aws_account" "exocompute_host" {
  # Looks up the central host account inside the Rubrik console
  name = "AgeroSharedServices" 
}

# ====================================================================
# 2. LOOK UP THE NEWLY ENROLLED ACCOUNT'S INTERNAL RUBRIK UUID
# ====================================================================
data "polaris_aws_account" "new_vended_account" {
  # This dynamically looks up the account name we just enrolled 
  # (e.g., testaft4) so we can grab its Rubrik UUID.
  name = data.aws_ssm_parameter.target_name.value

  # This depends_on forces Terraform to wait until the module completely 
  # finishes onboarding the account before trying to look it up!
  depends_on = [module.cloud_native]
}

# ====================================================================
# 3. CREATE THE APPLICATION MAPPING (Using the valid UUIDs)
# ====================================================================
resource "polaris_aws_exocompute" "map_exocompute" {
  # Passes the clean Rubrik UUID instead of the 12-digit AWS account number
  account_id      = data.polaris_aws_account.new_vended_account.id

  # Passes the central shared services Rubrik UUID
  host_account_id = data.polaris_aws_account.exocompute_host.id
}