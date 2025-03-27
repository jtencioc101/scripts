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
    # If no DNS servers are found, set the default Azure DNS IP address
    DNS_SERVER_IPS="168.63.129.16"
    echo "The VNet is configured with the default Azure DNS."
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
    else
        echo "FQDN: $fqdn, DNS Server IP: $dns_server_ip, Error: $result" >> error_output.log
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
echo "Creating debug pod with name $DEBUG_POD_NAME..."
kubectl apply -f $YAML_FILE

# Wait for the debug pod to be running
echo "Waiting for the debug pod to be running..."
kubectl wait --for=condition=Ready pod/$DEBUG_POD_NAME

# Run nslookup queries and log results into separate files
echo "Running nslookup for FQDNs ${FQDNS_ARRAY[@]} against all DNS servers in VNet..."
success_count=0
error_count=0

for dns_server_ip in $DNS_SERVER_IPS; do
    echo -n "."
    for fqdn in "${FQDNS_ARRAY[@]}"; do
        if run_nslookups "$dns_server_ip" "$fqdn"; then
            ((success_count++))
        else
            ((error_count++))
        fi
    done
done

echo "Nslookup completed. Success: $success_count, Errors: $error_count"

# Clean up debug pod
kubectl delete pod $DEBUG_POD_NAME --force 2>&1
rm -f $YAML_FILE

exit 0