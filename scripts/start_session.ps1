# Starts the lab VM and builds Bastion (Recipe 3.1 onward)
$rg   = "rg-intern-lab"
$vm   = "vm-lab01"
$vnet = "vm-lab01VNET"
$pip  = "pip-bastion-lab"
$bas  = "bas-intern-lab"
$loc  = "southafricanorth"

Write-Host "Starting VM..."
az vm start -g $rg -n $vm

Write-Host "Creating Bastion public IP..."
az network public-ip create -g $rg -n $pip --sku Standard --allocation-method Static -l $loc

Write-Host "Creating Bastion (takes 10 to 15 minutes, running in the background)..."
az network bastion create -g $rg -n $bas --vnet-name $vnet --public-ip-address $pip --sku Basic -l $loc --no-wait

Write-Host "Check progress with:  az network bastion list -g $rg -o table"
Write-Host "Connect when ProvisioningState says Succeeded."