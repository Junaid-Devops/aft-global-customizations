#!/bin/bash

echo "Executing Post-API Helpers"

#!/bin/bash
echo "=== Starting Post-API Customization Script ==="

# Execute your clean python automation task directly in the build sequence
python3 $BASE_PATH/api_helpers/python/netskope_enroll.py

echo "=== Completed Post-API Customization Script ==="