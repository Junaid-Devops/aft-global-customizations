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
}

data "aws_ssm_parameter" "target_name" {
  name = "/aft/AWSAccountName"
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
# 1. LOOK UP THE SHARED SERVICES EXACOMPUTE HOST ACCOUNT
# ====================================================================
# This pulls the internal Rubrik identifier for your central host account.
data "polaris_aws_account" "exocompute_host" {
  # This must match the exact name of your central host account inside the Rubrik console
  name = "AgeroSharedServices" 
}

# ====================================================================
# 2. CREATE THE APPLICATION MAPPING (As seen in the UI Screenshot)
# ====================================================================
resource "polaris_aws_exocompute" "map_exocompute" {
  # Points directly to the parameter value we looked up at the top of the file
  account_id      = data.aws_ssm_parameter.target_id.value

  # The central shared services account ID that holds the compute resources
  host_account_id = data.polaris_aws_account.exocompute_host.id
}