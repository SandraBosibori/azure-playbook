# Recipe 3.1: Bastion (command line)

Bastion lets me log in to a VM that has no public IP, through the browser.
I create it with commands because the portal did not offer Developer or Basic in southafricanorth.
Replace `vm-lab01VNET` with the exact name from step 1. --> az network vnet list -g rg-intern-lab -o table -->to check

## 1. Find the virtual network name

```powershell
az network vnet list -g rg-intern-lab -o table
```

Lists the virtual networks in my resource group. Azure created one when it built the VM.

## 2. Add the Bastion subnet

```powershell
az network vnet subnet create -g rg-intern-lab --vnet-name vm-lab01VNET -n AzureBastionSubnet --address-prefixes 10.0.1.0/26
```

Bastion needs its own subnet. The name must be exactly `AzureBastionSubnet`. `/26` is the smallest size Basic accepts.

## 3. Create a public IP for Bastion

```powershell
az network public-ip create -g rg-intern-lab -n pip-bastion-lab --sku Standard --allocation-method Static -l southafricanorth
```

Bastion is reached from the internet, so it needs a public IP. The VM still has none. Bastion requires the Standard SKU and a static address.

## 4. Create Bastion

```powershell
az network bastion create -g rg-intern-lab -n bas-intern-lab --vnet-name vm-lab01VNET --public-ip-address pip-bastion-lab --sku Basic -l southafricanorth
```

Creates the Bastion host. Takes 10 to 15 minutes. Success shows `"provisioningState": "Succeeded"`.

## 5. Connect (portal)

Portal, then vm-lab01, then Connect, then Bastion.
Authentication type: SSH Private Key from Local File. Username: azureuser. File: my private key (no .pub).

## 6. Check the VM only accepts keys

```bash
sudo apt update && sudo apt -y upgrade
sudo sshd -T | grep -i passwordauthentication
```

The first line patches the VM. The second must print `passwordauthentication no`.

## 7. Delete Bastion when finished (stops the hourly charge)

```powershell
az network bastion delete -g rg-intern-lab -n bas-intern-lab
az network public-ip delete -g rg-intern-lab -n pip-bastion-lab
az vm deallocate -g rg-intern-lab -n vm-lab01
```

The first removes Bastion. The second removes its public IP. The third stops the VM so it stops costing money.