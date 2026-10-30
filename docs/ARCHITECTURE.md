# Architecture Decision Records (ADR)

## ADR-001: Workload Identity Federation (GitHub OIDC) vs. Long-Lived Service Principal Secrets

### Context
Automating Terraform across CI/CD environments requires authenticating to Microsoft Azure. Traditional patterns generate Service Principal client secrets (`ARM_CLIENT_SECRET`) with manual rotation schedules.

### Decision
Adopt **Microsoft Entra Workload Identity Federation (GitHub OIDC)**:
1. **Zero Secret Footprint:** No credentials or client secrets are stored in GitHub Secrets.
2. **Short-Lived Tokens:** Azure validates OIDC JWT tokens minted on-demand for specific repository and branch claims.
3. **Least-Privilege Scoping:** Grants granular `Storage Blob Data Contributor` access on the Terraform state backend.

---

## ADR-002: Azure Blob Storage Lease Locking vs. External Lock DBs

### Context
Terraform state backends require locking mechanisms to prevent simultaneous concurrent state mutations and state corruption.

### Decision
Utilize **Native Azure Blob Storage Lease State Locking** via the `azurerm` backend:
- Automatically acquires and releases blob leases during `terraform plan` and `terraform apply`.
- Eliminates the need for external DynamoDB or CosmosDB lock tables.

