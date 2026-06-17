# ====================================================================
# 1. READ DYNAMIC DATA FROM THE TARGET VENDED ACCOUNT
# ====================================================================
# Both of these lookups will run inside the target account by default
# using your primary AFT provider context.

data "aws_ssm_parameter" "target_id" {
  name = "/aft/AWSAccountID"
}

data "aws_ssm_parameter" "target_name" {
  name = "/aft/AWSAccountName"
}

# ====================================================================
# 2. READ THE POLARIS CREDENTIAL FROM THE MANAGEMENT ACCOUNT SECRET
# ====================================================================
# Since the secret lives in the AFT Management Account, we pass it 
# through our 'aws.management' provider alias that we verified earlier!

data "aws_secretsmanager_secret" "polaris_creds" {
  provider = aws.management
  name     = "Rubrik-AWS-Account" # <-- Update this to your real secret path/name
}

data "aws_secretsmanager_secret_version" "polaris_creds_latest" {
  provider  = aws.management
  secret_id = data.secretsmanager_secret.polaris_creds.id
}

# ====================================================================
# 3. CONFIGURE THE POLARIS PROVIDER
# ====================================================================
provider "polaris" {
  # Pass the raw secret payload string directly to the provider credentials block
  credentials = data.aws_secretsmanager_secret_version.polaris_creds_latest.secret_string
}

# ====================================================================
# 4. RUBRIK CLOUD NATIVE MODULE
# ====================================================================
module "cloud_native" {
  source = "rubrikinc/polaris-cloud-native/aws"

  # Dynamically assigned from the target account's SSM store values
  aws_account_id   = data.aws_ssm_parameter.target_id.value
  aws_account_name = data.aws_ssm_parameter.target_name.value
  
  aws_regions      = ["us-west-2", "us-east-1", "us-east-2"]

  rsc_aws_features = [
    {
      name              = "CLOUD_NATIVE_ARCHIVAL"
      permission_groups = []
    },
    {
      name              = "CLOUD_NATIVE_PROTECTION"
      permission_groups = []
    },
    {
      name              = "CLOUD_NATIVE_S3_PROTECTION"
      permission_groups = []
    },
    {
      name              = "CLOUD_NATIVE_DYNAMODB_PROTECTION"
      permission_groups = []
    },
    {
      name              = "RDS_PROTECTION"
      permission_groups = []
    }
  ]
}