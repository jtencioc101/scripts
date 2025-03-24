#!/bin/bash

# Display the banner message at the start of the script
echo "###############################################################################################"
echo "# This script has been developed by the ACT team to assist with debugging.                    #"                   
echo "# It is designed solely for read-only operations and will not make any changes to the system. #"
echo "###############################################################################################"
echo ""

echo "This script will help us to determine if network connectivity can be established to the required endpoints for AKS"
sleep 3

echo "First, we must gather some information, please follow the prompmts"

# Prompt for user inputs
echo "Enter the resource group name:"
read resource_group

echo "Enter the VMSS name:"
read vmss_name

echo "Enter the instance ID:"
read instance_id

echo "Enter the AKS API Fully Qualified Domain Name (FQDN):"
read aks_fqdn

# Log file where raw data will be saved
log_file="vmss_output.txt"

# Run the az vmss command, save the output to the log file
echo "Fetching data from VMSS and saving to log file..."
az vmss run-command invoke \
  -g "$resource_group" \
  -n "$vmss_name" \
  --command-id RunShellScript \
  --instance-id "$instance_id" \
  --scripts @test.sh \
  --parameters "$aks_fqdn" \
  -o json | jq -r '.value[0].message | gsub("\\n"; "\n")' > "$log_file"

# Check if the log file was created successfully
if [ ! -f "$log_file" ]; then
  echo "Error: Log file not created. Exiting."
  exit 1
fi

# Process the log file and format it for the user
echo "Processing the log data and formatting the output..."

cat "$log_file" | \
  # Filter lines that contain DNS resolution or CURL connection
  grep -E "DNS resolution|CURL connection" | \
  # Remove unwanted lines (empty or stderr)
  sed '/^\s*$/d' | \
  # Format the data
  awk '
    BEGIN {
        dns="";
        curl="";
    }
    /DNS resolution/ {
        dns=$0;
    }
    /CURL connection/ {
        curl=$0;
        print dns, curl;
    }' | \
  # Neatly align the output by separating columns with a single space
  column -t

# Let the user know where the log file is saved
echo "The raw log data has been saved to: $log_file"

