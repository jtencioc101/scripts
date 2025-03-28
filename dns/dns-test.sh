#!/bin/bash
# Define color codes
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
BLUE='\033[34m'
CYAN='\033[36m'
RESET='\033[0m'
BOLD='\033[1m'
UNDERLINE='\033[4m'
# Function to show a spinner animation
spinner() {
    local pid=$1
    local delay=0.1
    local spin_chars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    while kill -0 $pid 2>/dev/null; do
        for i in $(seq 0 $((${#spin_chars} - 1))); do
            echo -ne "\r${YELLOW}[${spin_chars:$i:1}] Processing...${RESET}"
            sleep $delay
        done
    done
    echo -ne "\r"
}
# Function to prompt user input with validation
prompt_user() {
    local prompt_message=$1
    local var_name=$2
    local input_value=""
    
    while true; do
        echo -ne "${CYAN}$prompt_message: ${RESET}"
        read input_value
        if [ -n "$input_value" ]; then
            eval $var_name="$input_value"
            break
        else
            echo -e "${RED}Input cannot be empty. Please try again.${RESET}"
        fi
    done
}
# Function to validate VNet and Resource Group existence
validate_vnet() {
    while true; do
        DNS_SERVER_IPS=$(az network vnet show --name "$VNET_NAME" --resource-group "$RESOURCE_GROUP" --query "dhcpOptions.dnsServers[*]" -o tsv 2>/dev/null)
        if [ $? -eq 0 ]; then
            break
        else
            echo -e "${RED}Invalid VNet or Resource Group. Please re-enter.${RESET}"
            prompt_user "🔹 Enter the name of the VNet" VNET_NAME
            prompt_user "🔹 Enter the resource group name" RESOURCE_GROUP
        fi
    done
}
# Function to display header with underline and bold text
display_header() {
    echo -e "${CYAN}${BOLD}$1${RESET}"
    echo -e "${CYAN}=============================================${RESET}\n"
}
# Function to run nslookup and log output
run_nslookups() {
    local dns_server_ip=$1
    local fqdn=$2
    result=$(kubectl exec -it $DEBUG_POD_NAME -- sh -c "nslookup $fqdn $dns_server_ip" 2>&1)
    
    if [ $? -eq 0 ]; then
        echo -e "[$(date)] ✅ Success: $fqdn resolved via $dns_server_ip" >> success_output.log
        return 0
    else
        echo -e "[$(date)] ❌ Error: Failed to resolve $fqdn using $dns_server_ip. Output: $result" >> error_output.log
        return 1
    fi
}
# Section: User Input
clear
display_header "AKS DNS Check"
prompt_user "🔹 Enter the name of the VNet" VNET_NAME
prompt_user "🔹 Enter the resource group name" RESOURCE_GROUP
validate_vnet
# Retrieve DNS server IP addresses from the VNet
echo -e "\n🔍 ${YELLOW}Fetching DNS server information...${RESET}"
if [ -z "$DNS_SERVER_IPS" ]; then
    DNS_SERVER_IPS="168.63.129.16"
    echo -e "🛑 ${RED}The VNet is configured with the default Azure DNS. Using: 168.63.129.16${RESET}"
else
    echo -e "✅ ${GREEN}Retrieved DNS Servers:${RESET}"
fi
# Display DNS servers as a formatted list
echo -e "\n${CYAN}---------------------------------------------${RESET}"
for dns in $DNS_SERVER_IPS; do
    echo -e "  • ${YELLOW}$dns${RESET}"
done
echo -e "${CYAN}---------------------------------------------${RESET}\n"
# Prompt user for FQDNs to query
prompt_user "🔹 Enter the FQDNs to query (comma-separated)" FQDNS
FQDNS_ARRAY=(${FQDNS//,/ })
# Create Debug Pod
echo -e "\n🚀 ${BLUE}Creating debug pod...${RESET}"
DEBUG_POD_NAME="debug-pod-$(date +%s)-$(openssl rand -hex 4)"
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
kubectl apply -f $YAML_FILE & spinner $!
kubectl wait --for=condition=Ready pod/$DEBUG_POD_NAME --timeout=60s
# Run nslookup queries
echo -e "\n🌍 ${CYAN}Running nslookup queries...${RESET}"
success_count=0
error_count=0
for dns_server_ip in $DNS_SERVER_IPS; do
    echo -e "\n🔹 Querying DNS Server: ${YELLOW}$dns_server_ip${RESET}"
    for fqdn in "${FQDNS_ARRAY[@]}"; do
        if run_nslookups "$dns_server_ip" "$fqdn"; then
            ((success_count++))
        else
            ((error_count++))
        fi
    done
done
# Display final results with underline
echo -e "\n✅ ${GREEN}Nslookup completed. Success: $success_count, Errors: $error_count${RESET}"
echo -e "${CYAN}=============================================${RESET}"
# Inform user about log files
echo -e "\n📜 ${BLUE}Log files generated:${RESET}"
echo -e "- ✅ ${GREEN}success_output.log${RESET}: Contains successful DNS resolutions."
echo -e "- ❌ ${RED}error_output.log${RESET}: Contains failed DNS resolution attempts and errors."
# Cleanup
echo -e "\n🧹 ${RED}Cleaning up debug pod...${RESET}"
kubectl delete pod $DEBUG_POD_NAME --force >/dev/null 2>&1
rm -rf debug_pod.yaml
echo -e "✅ Cleanup complete."
exit 0