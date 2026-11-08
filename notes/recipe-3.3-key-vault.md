# Recipe 3.3: Secrets in the vault, not in the code

**Goal:** an app reading a secret with no password stored anywhere, using a managed identity.

**Environment:** `rg-intern-lab`, VM `vm-lab01`, vault `kv-playbook-12345a`, secret `DbConnection` (dummy value only).

---

## What I did

### 1. Create the vault (Azure RBAC mode)

```powershell
$KV = "kv-playbook-12345a"
az keyvault create -g rg-intern-lab -n $KV -l southafricanorth --enable-rbac-authorization true
$KV_ID = az keyvault show -n $KV --query id -o tsv
```

`--enable-rbac-authorization true` makes the vault use Azure roles instead of the older access policies. `$KV_ID` is the vault's resource ID, used as the **scope** of role assignments.

### 2. Give myself permission to write secrets

```powershell
$ME = az ad signed-in-user show --query id -o tsv
az role assignment create --role "Key Vault Secrets Officer" --assignee-object-id $ME --assignee-principal-type User --scope $KV_ID
```

Being Owner of the subscription does not grant access to secrets. Owner is a management-plane role, and secrets are data-plane, so I needed `Key Vault Secrets Officer`.

### 3. Store a dummy secret

```powershell
az keyvault secret set --vault-name $KV -n DbConnection --value "dummy-connection-string"
```

### 4. Give the VM an identity that can only read

```powershell
$VM_PRINCIPAL = az vm identity assign -g rg-intern-lab -n vm-lab01 --query systemAssignedIdentity -o tsv
az role assignment create --role "Key Vault Secrets User" --assignee-object-id $VM_PRINCIPAL --assignee-principal-type ServicePrincipal --scope $KV_ID
```

The first command creates a system-assigned managed identity for the VM. The second gives it `Key Vault Secrets User`, which can read secrets but not change them. The playbook's `--assignee-objectid` lost its hyphens in the PDF, so it is `--assignee-object-id`.

### 5. Read the secret from the VM (in the Bastion terminal)

```bash
TOKEN=$(curl -s -H "Metadata:true" "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://vault.azure.net" | jq -r .access_token)
curl -s -H "Authorization: Bearer $TOKEN" "https://kv-playbook-12345a.vault.azure.net/secrets/DbConnection?api-version=7.4" | jq -r .value
```

- `169.254.169.254` is the Instance Metadata Service. Only code on the VM can reach it.
- The first command gets a short-lived token for the VM's identity. The second sends that token to Key Vault.

**Result:** `dummy-connection-string`. No key or password was stored on the VM.

---

## How this would replace a `.env` file in a NestJS service

- Today the connection string sits in a `.env` file, which can leak through Git, backups, chat or a copied server.
- With a managed identity, the service asks Azure for a token when it starts, then fetches the secret from Key Vault. There is no secret in the repo or on disk.
- The identity has only `Key Vault Secrets User`, so a compromised app can read secrets but cannot change or delete them.
- To rotate the secret, I change it once in the vault. No files need redeploying.
- Limits: anything running on the VM can ask for that token, so roles should be narrow and scoped to one vault. The role must exist before the read works.

## What I learned

- A managed identity answers "who is this?" (authentication). The role assignment answers "what may it do?" (authorisation). The identity alone grants nothing.
- Key Vault has two permission layers: management (Owner, Contributor) and data (Secrets User, Secrets Officer).
- The VM reached the vault over the network, so it has outbound internet access and does not need a NAT Gateway.

## Taste test

- [x] The VM printed the dummy value
- [x] No key or password was stored on the VM

## Still to confirm and add

- [ ] Output or timing of the role assignments (any "Forbidden" retries I needed): `<fill in>`
- [ ] Confirm `BAD-ssh-any` from Recipe 3.2 is deleted

> Never put a real secret value or my subscription ID in this file.