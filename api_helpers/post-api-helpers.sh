#!/bin/bash

echo "Executing Post-API Helpers"
echo "=== Starting Post-API Customization Script ==="
unset AWS_PROFILE
# Using $DEFAULT_PATH/$CUSTOMIZATION accurately maps to your repo root folder in AFT
python3 $DEFAULT_PATH/$CUSTOMIZATION/api_helpers/python/netskope_enroll.py

echo "Targeting Vended Account ID: $VENDED_ACCOUNT_ID"

# 1. Query DynamoDB for the account name
ACCOUNT_NAME=$(aws dynamodb get-item \
  --table-name "aft-request-metadata" \
  --key "{\"id\": {\"S\": \"$VENDED_ACCOUNT_ID\"}}" \
  --query "Item.account_name.S" \
  --output text)

if [ -z "$ACCOUNT_NAME" ] || [ "$ACCOUNT_NAME" == "None" ]; then
    echo "ERROR: Could not find account name for ID $VENDED_ACCOUNT_ID in DynamoDB!"
    exit 1
fi

echo "Found Account Name: $ACCOUNT_NAME"

# 2. Write it natively to SSM (Overwriting previous run loop entries safely)
aws ssm put-parameter \
  --name "/aft/AWSAccountName" \
  --value "$ACCOUNT_NAME" \
  --type "String" \
  --overwrite
echo "=== Finished Post-API Customization Script ==="