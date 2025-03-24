#!/bin/bash

# Check if the first endpoint is provided as an argument
if [ -z "$1" ]; then
    echo "Error: No API endpoint provided. Please provide the API endpoint as an argument."
    echo "Usage: $0 <API_endpoint>"
    exit 1
fi

# Set the first endpoint from the user input (argument)
API=$1

# Define required FQDNs (starting with the user-provided first endpoint)
ENDPOINTS=(
    "$API"
    "mcr.microsoft.com"
    "mcr-0001.mcr-msedge.net"
    "management.azure.com"
    "packages.microsoft.com"
    "acs-mirror.azureedge.net"
    "packages.aks.azure.com"
    "security.ubuntu.com"
    "changelogs.ubuntu.com"
    "snapshot.ubuntu.com"
    "nvidia.github.io"
    "us.download.nvidia.com"
    "download.docker.com"
    "onegetcdn.azureedge.net"
    "go.microsoft.com"
    "www.msftconnecttest.com"
    "ctldl.windowsupdate.com"
)

# Initialize failure tracking arrays
FAILED_DNS=()
FAILED_CURL=()

# Function to check DNS resolution and CURL connectivity
check_connectivity() {
    local endpoint=$1

    # DNS check
    DNS_IP=$(dig $endpoint A +short)

    if [ -n "$DNS_IP" ]; then
        echo "DNS resolution successful for $endpoint to $DNS_IP"
    else
        echo "DNS resolution failed for $endpoint"
        FAILED_DNS+=("$endpoint")
    fi

    # CURL check (TCP port 443 for HTTPS)
    CURL_OUTPUT=$(curl -v -k --max-time 10 --silent --connect-timeout 5 "https://$endpoint" 2>&1)
    CURL_STATUS=$?

    if [[ $CURL_STATUS -eq 0 ]]; then
        echo "CURL connection successful for $endpoint"
    else
        # Capture specific error message from the curl output
        if echo "$CURL_OUTPUT" | grep -q "Connection refused"; then
            REASON="Connection refused"
        elif echo "$CURL_OUTPUT" | grep -q "Connection timed out"; then
            REASON="Timeout"
        elif echo "$CURL_OUTPUT" | grep -q "No route to host"; then
            REASON="No route to host"
        elif echo "$CURL_OUTPUT" | grep -q "Network is unreachable"; then
            REASON="Network unreachable"
        else
            REASON="Unknown error"
        fi

        echo "CURL connection failed for $endpoint - Reason: $REASON"
        FAILED_CURL+=("$endpoint")
    fi
}

# Run checks and collect results
for endpoint in "${ENDPOINTS[@]}"; do
    check_connectivity "$endpoint"
done

# Display summary in plain text format
if [ ${#FAILED_DNS[@]} -eq 0 ] && [ ${#FAILED_CURL[@]} -eq 0 ]; then
    echo "All endpoints are accessible!"
else
    if [ ${#FAILED_DNS[@]} -gt 0 ]; then
        echo "DNS Resolution Failed for the following endpoints:"
        for endpoint in "${FAILED_DNS[@]}"; do
            echo "- $endpoint"
        done
    fi

    if [ ${#FAILED_CURL[@]} -gt 0 ]; then
        echo "CURL Connectivity Failed for the following endpoints:"
        for endpoint in "${FAILED_CURL[@]}"; do
            echo "- $endpoint"
        done
    fi
fi

# Disclaimer with link to documentation
echo "Disclaimer: Please check the official AKS documentation for the required outbound endpoints at the following link: https://learn.microsoft.com/en-us/azure/aks/outbound-rules-control-egress"
