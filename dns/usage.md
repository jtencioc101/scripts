# AKS DNS Tool

## Overview
This script is designed to automate the process of troubleshooting network issues on Azure Kubernetes Service (AKS) nodes by performing `nslookup` queries against DNS servers in a specified Virtual Network (VNet). It leverages a temporary debug pod to execute these queries and logs the results for further analysis.

## Requirements
1. **jq**: A lightweight and flexible command-line JSON processor.
2. **kubectl**: The Kubernetes command-line tool, which you need to have set up and configured to interact with your AKS cluster.
3. **Azure CLI**: The Azure Command-Line Interface, required to fetch DNS server IPs from the specified VNet.
4. **Permissions**: The user should have enough permissions to get the VNET details as the script relies on the `az network vnet show ` command to get the list of configured DNS servers.

## Usage
To use this script, follow these steps:

1. **Save the Script**:
   Clone this repo and change directory to.

2. **Make the Script Executable**:
   Run the following command to make the script executable:
   ```bash
   chmod +x dns-test.sh
   ```

3. **Run the script**:
   ```bash
   ./dns-test.sh
   ```

4. **Provide information**:
   The script will prompt you to enter the following details:
   - VNet name
   - Resource group name
   - AKS nodepool name
   - Comma-separated list of FQDNs to query

5. **Review output**:
   After running the script, it will create a debug pod and run nslookup queries for each specified FQDN against all DNS servers in the VNet. The results will be logged in two files:

   `success_output.log`: Contains successful nslookup queries.
   `error_output.log`: Contains failed nslookup queries.

**Example**:
```bash
./dns-test.sh

Enter the name of the VNet: my-vnet
Enter the resource group name: my-resource-group
Enter the AKS nodepool name: my-nodepool
Enter the FQDNs to query (comma-separated): example.com,google.com

Creating debug pod with name debug-pod-1633072800-abcd...
Debug pod created: debug-pod-1633072800-abcd
Waiting for the debug pod to be running...

Running nslookup for FQDNs example.com,google.com against all DNS servers in VNet...

Summary:
Successful nslookup queries: 2
Failed nslookup queries: 0

Results are logged in the following files:
1. success_output.log (Successful nslookup queries)
2. error_output.log (Failed nslookup queries)
```