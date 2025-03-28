# AKS DNS Check

## Overview
This Bash script automates the process of retrieving and testing DNS configurations for an Azure Virtual Network (VNet). It queries the DNS servers configured for the VNet and performs `nslookup` tests for user-specified Fully Qualified Domain Names (FQDNs) using a temporary Kubernetes debug pod.

## Features
- Validates user-provided VNet and Resource Group names.
- Retrieves DNS server IPs associated with the VNet.
- Uses the default Azure DNS (168.63.129.16) if no custom DNS servers are configured.
- Allows users to input multiple FQDNs for DNS resolution tests.
- Creates a temporary Kubernetes debug pod to perform `nslookup` queries.
- Logs successful and failed DNS resolution attempts.
- Provides clear visual output with color highlights and status messages.
- Automatically cleans up the debug pod after execution.

## Prerequisites
Before running the script, ensure you have the following installed and configured:
- **Azure CLI** (`az` command-line tool)
- **Kubernetes CLI** (`kubectl` command-line tool)
- Access to an Azure Kubernetes Service (AKS) cluster
- The necessary permissions to retrieve Azure VNet details and manage Kubernetes pods

## Usage

1. Clone the repository or copy the script to your local machine.
2. Make the script executable:
   ```bash
   chmod +x dns-test.sh
   ```
3. Run the script:
   ```bash
   ./dns-test.sh
   ```
4. Follow the on-screen prompts to enter the required information:
   - VNet name
   - Resource Group name
   - FQDNs to query (comma-separated)
5. The script will:
   - Validate the provided VNet and Resource Group.
   - Retrieve the associated DNS servers.
   - Run `nslookup` queries using a temporary Kubernetes debug pod.
   - Log successful and failed lookups.
   - Clean up resources at the end.

## Output
- The script displays retrieved DNS servers in a formatted list.
- `nslookup` results are categorized into:
  - `success_output.log` → Contains successful DNS lookups.
  - `error_output.log` → Logs errors encountered during DNS queries.
- At the end of execution, the script cleans up the debug pod automatically.

## Example Execution
```
🔹 Enter the name of the VNet: my-vnet
🔹 Enter the resource group name: my-resource-group
🔍 Fetching DNS server information...
✅ Retrieved DNS Servers:
  • 10.0.0.10
  • 10.0.0.11

🔹 Enter the FQDNs to query (comma-separated): example.com, myapp.internal
🚀 Creating debug pod...
🌍 Running nslookup queries...

🔹 Querying DNS Server: 10.0.0.10
✅ Success: example.com resolved via 10.0.0.10
❌ Error: Failed to resolve myapp.internal using 10.0.0.10

🔹 Querying DNS Server: 10.0.0.11
✅ Success: example.com resolved via 10.0.0.11
❌ Error: Failed to resolve myapp.internal using 10.0.0.11

✅ Nslookup completed. Success: 2, Errors: 2
📜 Log files generated:
- ✅ success_output.log: Contains successful DNS resolutions.
- ❌ error_output.log: Contains failed DNS resolution attempts and errors.
🧹 Cleaning up debug pod...
✅ Cleanup complete.
```

## Troubleshooting
- **Invalid VNet or Resource Group:** The script prompts for re-entry if incorrect information is provided.
- **No Custom DNS Servers Found:** The script uses `168.63.129.16` if no custom DNS is set.
- **Kubernetes Debug Pod Issues:** Ensure your AKS cluster is running and accessible.
