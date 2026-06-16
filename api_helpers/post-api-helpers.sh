#!/bin/bash

echo "Executing Post-API Helpers"
echo "=== Starting Post-API Customization Script ==="
unset AWS_PROFILE
# Using $DEFAULT_PATH/$CUSTOMIZATION accurately maps to your repo root folder in AFT
python3 $DEFAULT_PATH/$CUSTOMIZATION/api_helpers/python/netskope_enroll.py

# Ensure we have our dynamic account ID from the environment
echo "Targeting Vended Account ID: $VENDED_ACCOUNT_ID"

echo "Querying AFT DynamoDB table for the account name..."
# 1. Query the DynamoDB table using the Account ID as the hash key
ACCOUNT_NAME=$(aws dynamodb get-item \
  --table-name "aft-request-metadata" \
  --key "{\"id\": {\"S\": \"$VENDED_ACCOUNT_ID\"}}" \
  --query "Item.account_name.S" \
  --output text)

# Quick sanity check to make sure we didn't get an empty response
if [ -z "$ACCOUNT_NAME" ] || [ "$ACCOUNT_NAME" == "None" ]; then
    echo "ERROR: Could not find account name for ID $VENDED_ACCOUNT_ID in DynamoDB!"
    exit 1
fi

echo "Found Account Name: $ACCOUNT_NAME"

# 2. Use sed to replace the placeholder in your ssm.tf file
# (Using | as a delimiter in sed in case the account name has spaces or slashes)
sed -i "s|value = \"replacewithaccountname\"|value = \"$ACCOUNT_NAME\"|g" ssm.tf

echo "Successfully updated ssm.tf with the real account name!"
echo "=== Finished Post-API Customization Script ==="