# ====================================================================
# 1. DEFINE EXACT PROVIDER SOURCES
# ====================================================================
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      #version = ">= 5.26.0"      
    }
    polaris = {
      source  = "rubrikinc/polaris"
      version = ">= 1.0.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
# ====================================================================
# 2. MANAGEMENT PROVIDER (For Secrets Manager lookup)
# ====================================================================
provider "aws" {
  alias  = "management"
  region = "us-east-1"
  assume_role {
    role_arn = "arn:aws:iam::678780124859:role/AWSAFTExecution"
  }
}

# ====================================================================
# 3. POLARIS CONFIGURATION & MODULE
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
  aws_regions      = ["us-west-2", "us-east-1","us-east-2"]

  rsc_aws_features = [
    { name = "CLOUD_NATIVE_ARCHIVAL",       permission_groups = [] },
    { name = "CLOUD_NATIVE_PROTECTION",     permission_groups = [] },
    { name = "CLOUD_NATIVE_S3_PROTECTION",  permission_groups = [] },
    { name = "CLOUD_NATIVE_DYNAMODB_PROTECTION", permission_groups = [] },
    { name = "RDS_PROTECTION",              permission_groups = [] }
  ]
}