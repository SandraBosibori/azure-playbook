# Deletes Bastion and its public IP, then stops the VM, so nothing keeps billing
$rg  = "rg-intern-lab"
$vm  = "vm-lab01"
$pip = "pip-bastion-lab"
$bas = "bas-intern-lab"

Write-Host "Deleting Bastion..."
az network bastion delete -g $rg -n $bas

Write-Host "Deleting Bastion public IP..."
az network public-ip delete -g $rg -n $pip

Write-Host "Deallocating VM..."
az vm deallocate -g $rg -n $vm

Write-Host "Checking what is left..."
az network bastion list -g $rg -o table
az network public-ip list -g $rg -o table
az vm list -d -o table