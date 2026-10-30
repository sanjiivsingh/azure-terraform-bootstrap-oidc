# 🚀 Azure Terraform Remote State & GitHub OIDC Bootstrap

[![Terraform 1.9+](https://img.shields.io/badge/Terraform-1.9+-844FBA?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![Azure Provider v4+](https://img.shields.io/badge/AzureRM-v4.0+-0078D4?style=for-the-badge&logo=microsoftazure&logoColor=white)](https://registry.terraform.io/providers/hashicorp/azurerm/latest)
[![CI/CD Validation](https://github.com/sanjiivsingh/azure-terraform-bootstrap-oidc/actions/workflows/ci.yml/badge.svg)](https://github.com/sanjiivsingh/azure-terraform-bootstrap-oidc/actions/workflows/ci.yml)
[![Status: Reference Architecture](https://img.shields.io/badge/Status-Reference_Architecture_(Statically_Validated)-10B981?style=for-the-badge)](https://github.com/sanjiivsingh/azure-terraform-bootstrap-oidc)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

> **Reference Architecture · Statically Validated**  
> Foundational bootstrap blueprint for provisioning secure Azure remote state backends (Blob Storage with automated lease locking) and Microsoft Entra Workload Identity Federation (GitHub Actions passwordless OIDC authentication).

---

## 🎯 The Problem This Bootstrap Solves

1. **State File Exposure:** Committing `.tfstate` files locally or in git creates critical credential leaks and concurrency collisions.
2. **Secret Rotation Overhead:** Using long-lived Service Principal client secrets (`ARM_CLIENT_SECRET`) in GitHub Secrets introduces security exposure and expiration outages.
3. **Missing State Locks:** Concurrent team deployments without state locking cause silent state corruption.

**Solution:** This bootstrap provisions an isolated, versioned Azure Storage Account with blob lease locking, paired with passwordless GitHub OIDC federated identity credentials.

---

## 📐 Architecture Overview

```mermaid
flowchart LR
    subgraph GitHub["🐙 GitHub Enterprise / Actions"]
        RUNNER["GitHub Actions Runner\n(main & PR branches)"]
    end

    subgraph Entra["🛡️ Microsoft Entra ID"]
        APP["App Registration & Service Principal"]
        FED["Federated Identity Credentials\n(Subject Claim: repo:sanjiivsingh/*)"]
    end

    subgraph State["💾 Azure State Storage"]
        ST["Storage Account (Standard LRS)\nTLS 1.2+ & Blob Versioning"]
        CONTAINER["Private Container: tfstate\n(Native Blob Lease Locking)"]
    end

    RUNNER -->|OIDC JWT Exchange| FED
    FED --> APP
    APP -->|Short-Lived Token| ST
    ST --> CONTAINER
```

---

## ⚙️ Quickstart Usage

### 1. Initialize & Review Plan
```bash
terraform init
terraform fmt -check
terraform validate
terraform plan -out=bootstrap.tfplan
```

### 2. Deploy
```bash
terraform apply bootstrap.tfplan
```

### 3. Consume in Downstream Repositories
Add the backend configuration block into your child landing zones (`provider.tf`):
```terraform
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-bootstrap"
    storage_account_name = "<OUTPUT_STORAGE_ACCOUNT_NAME>"
    container_name       = "tfstate"
    key                  = "<project-name>/dev.terraform.tfstate"
    use_oidc             = true
  }
}
```

---

## 💰 Cost & Resource Teardown

* **Monthly Cost:** Minimal storage consumption (~$0.50 – $2.00 / month).
* **Teardown Notice:** Remote state storage holds active infrastructure maps. Before destroying the bootstrap storage account, ensure all downstream environments have been migrated or destroyed.

```bash
terraform destroy -auto-approve
```

---

## 👨‍💻 Author & Cloud Consultant

**Sanjeev Singh**  
*Freelance Azure Cloud Engineer | Terraform & Infrastructure Automation*  
* 🌐 **Portfolio**: [sanjeevsingh.oneps.in](https://sanjeevsingh.oneps.in)  
* 💼 **LinkedIn**: [linkedin.com/in/sanjiivsingh](https://linkedin.com/in/sanjiivsingh)  
* 🐙 **GitHub**: [github.com/sanjiivsingh](https://github.com/sanjiivsingh)

---

## 📄 License
Licensed under the [MIT License](LICENSE).

