# Disaster Recovery & State Restoration Guide

## 1. High Availability Architecture

Remote state storage is the most sensitive asset in an automated cloud platform. This platform implements multi-tier data protection:

| Threat | Mitigating Control | Recovery Mechanism | Recovery Time Objective (RTO) |
| :--- | :--- | :--- | :--- |
| **Accidental State Deletion** | Blob Soft Delete (30 Days) | `az storage blob undelete` | < 5 Minutes |
| **Accidental Container Deletion** | Container Soft Delete (30 Days) | Portal / CLI Container Restore | < 10 Minutes |
| **Bad Apply / State Corruption** | Blob Versioning (Continuous) | Promote historical version | < 10 Minutes |
| **Concurrent Mutation Collisions** | Native Blob Lease Locks | Lease timeout / Manual break | Immediate |
| **Azure Primary Region Outage** | Configurable GRS Replication | Azure Storage Account Failover | < 1 Hour |

---

## 2. Recovery Scenarios & Operational Runbooks

### Scenario A: Recovering an Accidentally Deleted State Blob
If a state blob is deleted via Azure Portal or CLI:
```bash
az storage blob undelete \
  --account-name "<STORAGE_ACCOUNT_NAME>" \
  --container-name "tfstate" \
  --name "landing-zone/dev.terraform.tfstate" \
  --auth-mode login
```

### Scenario B: Rolling Back Corrupted State Using Blob Versioning
If a failed deployment or manual intervention corrupts `.tfstate`:
1. List previous blob versions:
   ```bash
   az storage blob list \
     --account-name "<STORAGE_ACCOUNT_NAME>" \
     --container-name "tfstate" \
     --prefix "landing-zone/dev.terraform.tfstate" \
     --include v \
     --auth-mode login \
     --query "[].{VersionId:versionId, LastModified:properties.lastModified}" -o table
   ```
2. Download the desired pre-corruption version:
   ```bash
   az storage blob download \
     --account-name "<STORAGE_ACCOUNT_NAME>" \
     --container-name "tfstate" \
     --name "landing-zone/dev.terraform.tfstate" \
     --version-id "<TARGET_VERSION_ID>" \
     --file "recovered_dev.tfstate" \
     --auth-mode login
   ```
3. Push the recovered state back to the active blob:
   ```bash
   terraform state push recovered_dev.tfstate
   ```

### Scenario C: Breaking a Stale Blob Lease Lock
If a pipeline terminates during plan/apply and leaves a lock active:
```bash
az storage blob lease break \
  --account-name "<STORAGE_ACCOUNT_NAME>" \
  --container-name "tfstate" \
  --blob-name "landing-zone/dev.terraform.tfstate" \
  --auth-mode login
```

