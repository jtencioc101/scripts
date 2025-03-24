# Why?
There is a specific need to automate network connectivity issues from AKS clusters to the required endpoints

# How?
The script will take input from the enduser and will run `az vmss run-command invoke ` to test DNS resolution and TCP connectivity to the required endpoints
mentioned on the follwing link:
https://learn.microsoft.com/en-us/azure/aks/outbound-rules-control-egress


# Prerequisites:
- jq

# Steps / how to
- clone this repo
- cd scripts/check_outbound
- chmod +x endpoints.sh main.sh
- ./main.sh
- follow the prompts, provide the required info.
