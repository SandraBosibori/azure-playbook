Recipe 2.1 - Azure Sandbox
Subscription
Azure Subscription 1

Budget
USD 20/month

Alert Thresholds
50%
80%
100%
Resource Group
rg-intern-lab

Region
southafricanorth

Commands Used
az account show -o table

az group create -n rg-intern-lab -l southafricanorth --tags owner=sandra environment=lab

az group list -o table