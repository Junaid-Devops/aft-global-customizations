#!/bin/bash

echo "Executing Post-API Helpers"
echo "=== Starting Post-API Customization Script ==="
unset AWS_PROFILE
# Using $DEFAULT_PATH/$CUSTOMIZATION accurately maps to your repo root folder in AFT
python3 $DEFAULT_PATH/$CUSTOMIZATION/api_helpers/python/netskope_enroll.py

echo "=== Completed Post-API Customization Script ==="