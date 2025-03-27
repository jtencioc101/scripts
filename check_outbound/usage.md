# Network Troubleshooting Script for AKS Nodes

## Overview

This script aims to assist with debugging network issues on Azure Kubernetes Service (AKS) nodes. It is designed solely for read-only operations and will not make any changes to the system.

## Purpose

The purpose of this script is to help determine if network connectivity can be established to the required endpoints for AKS. It gathers necessary information from the user, runs a shell command on an Azure VM Scale Set (VMSS) instance, and processes the output to provide formatted results.

## Usage

To use this script, you need to have:
-  `bash` installed
- Access to the Azure CLI (`az`)
- A valid Azure resource group that contains the AKS cluster
- The necessary permissions to run commands on VMSS instances within the specified resource group

### Running the Script

1. **Save the Script**: Clone this repository and change to the scripts/check_outbound directory.
2. **Make the Script Executable**: Run the following command in your terminal:
   ```bash
   chmod +x main.sh endpoints.sh
3. **Execute the Script with Parameters**: The script requires several parameters to be provided via command-line options. You can run the script using the -h option to see detailed usage information.
    ```bash
    ./main.sh -h
    ```
    This will display the following usage help:
      ```
      Usage: main.sh -g <resource_group> -n <vmss_name> -i <instance_id> -f <aks_fqdn>

      Options:
        -g, --resource-group <resource_group>    Azure resource group name
        -n, --vmss-name <vmss_name>            VMSS instance name
        -i, --instance-id <instance_id>        Instance ID in the VMSS (0-based)
        -f, --aks-fqdn <aks_fqdn>              AKS FQDN to test connectivity for
    ```

    Example:
    ./main.sh -g myResourceGroup -n myVMSS -i 1 -f myAKSFQDN.com

    This command will: 
    - Connect to the specified VMSS instance.
    - Run a shell command to test network connectivity for the given AKS FQDN.
    - Save and process the output, displaying formatted results.

    **Output**

    The script will save the raw output of the command in vmss_output.txt and also format and display the relevant parts of the output. The formatted output includes details about DNS resolution and CURL connections to the specified AKS FQDN.

    **Notes**

    Ensure you have the necessary permissions to run commands on VMSS instances within the specified resource group.
    This script assumes that the jq tool is installed, which is used for processing JSON data from Azure CLI commands. If jq is not installed, you can install it using:
    ```bash
    sudo apt-get update && sudo apt-get install -y jq
