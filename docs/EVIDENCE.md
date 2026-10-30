# Verification & Evidence Summary

## 1. Static Module Validation Evidence

```bash
terraform init -backend=false
terraform validate
```
Output:
```text
Success! The configuration is valid.
```

---

## 2. Estimated Infrastructure Cost (Infracost Summary)

| Component | SKU / Tier | Count | Est. Monthly Cost (USD) |
| :--- | :--- | :---: | :---: |
| **Storage Account** | Standard LRS (Hot Tier) | 1 | ~$0.50 – $2.00 |
| **Blob Storage Container** | Private (State Blobs) | 1 | Capacity-based (< 50MB) |
| **Microsoft Entra Application** | Free Tier | 1 | $0.00 |
| **Federated Identity Credentials** | Free Tier (GitHub OIDC) | 8 | $0.00 |
| **Total Base Monthly Est.** | | | **~$0.50 – $2.00 / month** |

