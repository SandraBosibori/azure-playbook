# Creates a private Ubuntu VM: no public IP, no inbound rules (Recipe 3.1)
$rg = "rg-intern-lab"
$vm = "vm-lab01"

az vm create -g $rg -n $vm --image Ubuntu2404 --size Standard_B2s_v2 `
  --admin-username azureuser --ssh-key-values "$HOME/.ssh/id_ed25519.pub" `
  --public-ip-address '""' --nsg-rule NONE --tags owner=sandra environment=lab