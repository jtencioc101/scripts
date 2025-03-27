#!/bin/bash

# Display the banner message at the start of the script
echo "###############################################################################################"
echo "# This script aims to assist with debugging.                                                  #"                   
echo "# It is designed solely for read-only operations and will not make any changes to the system. #"
echo "###############################################################################################"
echo ""

# Function to display usage information
usage() {
  echo "Usage: $0 -g <resource_group> -n <vmss_name> -i <instance_id> -f <aks_fqdn>"
  echo ""
  echo "Options:"
  echo "  -g, --resource-group    Azure resource group name"
  echo "  -n, --vmss-name         VMSS (Virtual Machine Scale Set) name"
  echo "  -i, --instance-id       Instance ID of the VM in the scale set"
  echo "  -f, --aks-fqdn          AKS API Fully Qualified Domain Name (FQDN)"
  exit 1
}

# Parse command-line options
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -g|--resource-group) resource_group="$2"; shift ;;
    -n|--vmss-name) vmss_name="$2"; shift ;;
    -i|--instance-id) instance_id="$2"; shift ;;
    -f|--aks-fqdn) aks_fqdn="$2"; shift ;;
    *) usage ;;
  esac
  shift
done

# Check if all required parameters are provided
if [ -z "$resource_group" ] || [ -z "$vmss_name" ] || [ -z "$instance_id" ] || [ -z "$aks_fqdn" ]; then
  echo "Error: Missing required parameters. Use '-h' for help."
  usage
fi

# Log file where raw data will be saved
log_file="vmss_output.txt"

# Run the az vmss command, save the output to the log file
echo "Fetching data from VMSS and saving to log file..."
az vmss run-command invoke \
  -g "$resource_group" \
  -n "$vmss_name" \
  --command-id RunShellScript \
  --instance-id "$instance_id" \
  --scripts @endpoints.sh \
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
