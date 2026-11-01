# Verification & Engineering Evidence

## 1. Automated Static Validation Gates

All tests executed locally and verified:

### A. Terraform Format & Recursive Code Validation
```bash
terraform fmt -check -recursive
```
* **Status:** Passed (0 errors)

### B. Root Module Initialization & Validation
```bash
terraform init -backend=false
terraform validate
```
* **Output:**
  ```text
  Terraform has been successfully initialized!
  Success! The configuration is valid.
  ```

### C. Bootstrap Environment Initialization & Validation
```bash
cd environments/bootstrap
terraform init -backend=false
terraform validate
```
* **Output:**
  ```text
  Terraform has been successfully initialized!
  Success! The configuration is valid.
  ```

### D. TFLint Static Linting
```bash
tflint --recursive
```
* **Status:** Passed (0 issues detected)

### E. Checkov Static Security Analysis
```bash
checkov -d . --config-file checkov.yaml
```
* **Results:**
  ```text
  terraform scan results:
  Passed checks: 16, Failed checks: 0, Skipped checks: 0
  ```

### F. Gitleaks Secret Scanning
```bash
gitleaks detect --no-git -v
```
* **Results:**
  ```text
  3:54PM INF scanned ~200844 bytes (200.84 KB) in 26.2ms
  3:54PM INF no leaks found
  ```

---

## 2. Infrastructure Cost Estimate

| Component | Resource Type | SKU / Tier | Count | Est. Monthly Cost (USD) |
| :--- | :--- | :--- | :---: | :---: |
| **Storage Account** | `azurerm_storage_account` | Standard LRS (Hot Tier) | 1 | ~$0.50 – $2.00 |
| **State Container** | `azurerm_storage_container` | Private (Blob Storage) | 1 | < $0.05 (< 50MB) |
| **Entra App Registrations** | `azuread_application` | Microsoft Entra ID Free | 5 | $0.00 |
| **Federated Credentials** | `azuread_federated_identity` | Workload Identity Free | ~12 | $0.00 |
| **RBAC Role Assignments** | `azurerm_role_assignment` | Azure RBAC Control Plane | 6 | $0.00 |
| **Private Endpoint (Optional)** | `azurerm_private_endpoint` | Azure Private Link | 1 (Opt) | ~$7.30 / month |
| **Total Base Monthly Cost** | | | | **~$0.50 – $2.00 / month** |
