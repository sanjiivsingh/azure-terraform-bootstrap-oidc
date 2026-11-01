# Deployment & Operational Runbook

## 1. Prerequisites & Access Requirements

Before deploying the bootstrap platform, ensure you possess:
- **Terraform:** `>= 1.9.0`
- **Azure CLI:** `>= 2.60.0`
- **Azure Permissions:** `Owner` or `User Access Administrator` + `Contributor` on the target Azure Subscription.
- **Microsoft Entra ID Permissions:** `Application Administrator` or `Cloud Application Administrator` to register Entra applications and service principals.

---

## 2. Step-by-Step Initial Deployment

### Step 1: Clone Repository & Authenticate
```bash
git clone https://github.com/sanjiivsingh/azure-terraform-bootstrap-oidc.git
cd azure-terraform-bootstrap-oidc/environments/bootstrap

az login
az account set --subscription "<YOUR_SUBSCRIPTION_ID>"
```

### Step 2: Configure Deployment Variables
```bash
cp terraform.tfvars.example terraform.tfvars
```
Edit `terraform.tfvars` with:
- `github_organization`: Your GitHub username or organization (e.g. `sanjiivsingh`).
- `github_repositories`: List of downstream landing zone repositories.

### Step 3: Initialize & Review Plan
```bash
terraform init -backend=false
terraform fmt -check
terraform validate
terraform plan -out=bootstrap.tfplan
```

### Step 4: Apply Bootstrap Infrastructure
```bash
terraform apply bootstrap.tfplan
```

### Step 5: Migrate Local State to Remote Azure Blob
1. Inspect the generated outputs:
   ```bash
   terraform output
   ```
2. Open `backend.tf` and uncomment the `backend "azurerm"` block, inserting the generated `storage_account_name`.
3. Execute state migration:
   ```bash
   terraform init -migrate-state
   ```
4. Confirm `yes` when prompted.

---

## 3. Verifying OIDC Authentication in GitHub Actions

1. Note the output Client IDs:
   ```bash
   terraform output bootstrap_admin_client_id
   terraform output environment_client_ids
   ```
2. Navigate to your GitHub repository > `Settings` > `Secrets and variables` > `Actions`.
3. Create repository variables:
   - `AZURE_CLIENT_ID_PLAN`: Output for `dev-plan`
   - `AZURE_CLIENT_ID_APPLY`: Output for `dev-apply`
   - `AZURE_TENANT_ID`: Microsoft Entra Tenant ID
   - `AZURE_SUBSCRIPTION_ID`: Azure Subscription ID
4. Trigger the `.github/workflows/terraform-plan.yml` workflow via `Run workflow` to verify successful token exchange.

---

## 4. Teardown & Decommissioning Policy

> [!CAUTION]
> **CRITICAL DATA LOSS WARNING:**
> Never destroy the bootstrap Storage Account while downstream landing zones or workloads are utilizing it for remote state storage. Destroying the state storage account irreversibly eliminates infrastructure maps and lock records.

### Safe Decommissioning Procedure
1. Destroy all downstream workload and landing zone resources first (`terraform destroy`).
2. Verify the `tfstate` container holds no active state files other than `bootstrap/terraform.tfstate`.
3. Migrate bootstrap state back to local disk:
   - Comment out `backend "azurerm"` in `backend.tf`.
   - Run `terraform init -migrate-state`.
4. Trigger destruction:
   ```bash
   terraform destroy -auto-approve
   ```
