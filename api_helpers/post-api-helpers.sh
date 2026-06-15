#!/bin/bash

echo "Executing Post-API Helpers"
echo "=== Starting Post-API Customization Script ==="
unset AWS_PROFILE
# Using $DEFAULT_PATH/$CUSTOMIZATION accurately maps to your repo root folder in AFT
python3 $DEFAULT_PATH/$CUSTOMIZATION/api_helpers/python/netskope_enroll.py

echo "Creating dynamic, isolated SSM parameter for Account: $VENDED_ACCOUNT_ID"

aws ssm put-parameter \
  --name "/aft/accounts/${VENDED_ACCOUNT_ID}/active" \
  --value "$VENDED_ACCOUNT_ID" \
  --type "String" \
  --overwrite \
  --description "Isolating runtime variable for TFC execution loop"

echo "=== Completed Post-API Customization Script ==="
