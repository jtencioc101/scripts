# Why?
There is a specific need to automate network connectivity issues from AKS clusters to the required endpoints

# How?
The script will take input from the enduser and will run `az vmss-command invoke ` with a set of tests to the required enpoints as per
the documentation found here:
https://learn.microsoft.com/en-us/azure/aks/outbound-rules-control-egress


# Prerequisites:
- jq

- clone this repo
- cd scripts/check_outbound
- chmod +x endpoints.sh main.sh
- ./main.sh
- follow the prompts, provide the required info.
