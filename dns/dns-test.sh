#!/bin/bash

# Function to prompt user input
prompt_user() {
    read -p "$1: " $2
}

# Prompt user for required data
prompt_user "Enter the name of the VNet" VNET_NAME
prompt_user "Enter the resource group name" RESOURCE_GROUP
prompt_user "Enter the AKS nodepool name" AKS_NODEPOOL_NAME

# Step 1: Retrieve DNS server IP addresses from the VNet
DNS_SERVER_IPS=$(az network vnet show --name "$VNET_NAME" --resource-group "$RESOURCE_GROUP" --query "dhcpOptions.dnsServers[*]" -o tsv)

# Check if we got any DNS servers and handle errors
if [ -z "$DNS_SERVER_IPS" ]; then
    # If the default Azure DNS is configured the az network show command won't return any value
    # hardcoding the ip address in case this is being used
    DNS_SERVER_IPS="168.63.129.16"
    echo "=================================================="
    echo "The VNet is configured with the default Azure DNS."
    echo "=================================================="
fi

echo "Retrieved DNS Servers: $DNS_SERVER_IPS"

# Prompt user to enter multiple FQDNs separated by commas
prompt_user "Enter the FQDNs to query (comma-separated):" FQDNS
FQDNS_ARRAY=(${FQDNS//,/ })

# Define a function to run nslookup commands in the debug pod and log output
run_nslookups() {
    local dns_server_ip=$1
    local fqdn=$2
    
    # Execute nslookup command inside the debug pod and capture the output
    result=$(kubectl exec -it $DEBUG_POD_NAME -- sh -c "nslookup $fqdn $dns_server_ip" 2>&1)
    
    if [ $? -eq 0 ]; then
        echo "$result" >> success_output.log
        return 0
    else
        echo "FQDN: $fqdn, DNS Server IP: $dns_server_ip, Error: $result" >> error_output.log
        return 1
    fi
}

# Create a unique name for the debug pod
DEBUG_POD_NAME="debug-pod-$(date +%s)-$(openssl rand -hex 4)"

# Create a YAML file for the debug pod
YAML_FILE="debug_pod.yaml"

cat <<EOF > $YAML_FILE
apiVersion: v1
kind: Pod
metadata:
  name: $DEBUG_POD_NAME
spec:
  containers:
  - name: busybox
    image: mcr.microsoft.com/cbl-mariner/busybox:2.0
    command: ["sh", "-c"]
    args:
    - "while true; do sleep 1; done"
EOF

# Apply the YAML file to create the debug pod
echo "=================================================="
echo "Creating debug pod with name $DEBUG_POD_NAME..."
echo "=================================================="
kubectl apply -f $YAML_FILE

# Wait for the debug pod to be running
echo "=========================================="
echo "Waiting for the debug pod to be running..."
echo "=========================================="
kubectl wait --for=condition=Ready pod/$DEBUG_POD_NAME

# Run nslookup queries and log results into separate files
echo "==============================================================================="
echo "Running nslookup for FQDNs ${FQDNS_ARRAY[@]} against all DNS servers in VNet..."
echo "==============================================================================="

success_count=0
error_count=0

# Loop through each DNS server and run nslookups for each FQDN
for dns_server_ip in $DNS_SERVER_IPS; do
    echo "=============================================================="
    echo "Running nslookup queries against DNS server IP: $dns_server_ip"
    echo "=============================================================="
    for fqdn in "${FQDNS_ARRAY[@]}"; do
        if run_nslookups "$dns_server_ip" "$fqdn"; then
            ((success_count++))
        else
            ((error_count++))
        fi
    done
done

# Final output
echo "================================================================="
echo "Nslookup completed. Success: $success_count, Errors: $error_count"
echo "================================================================="

# Inform user about the log files and their content
echo "Script execution complete."
echo "Results are logged in the following files:"
echo "- success_output.log: Contains successful nslookup results for each FQDN."
echo "- error_output.log: Contains failed nslookup attempts and errors."

# Clean up the debug pod and YAML file
kubectl delete pod $DEBUG_POD_NAME --force >/dev/null 2>&1
rm -rf debug_pod.yaml

exit 0