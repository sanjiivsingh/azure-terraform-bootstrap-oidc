# ADR-002: Azure Blob Storage Lease State Locking vs. External Databases

## Status
Accepted

## Context
Terraform state backends must enforce concurrency locking to prevent multiple engineers or CI runs from modifying state simultaneously, which results in silent state corruption.

## Decision
Utilize **Native Azure Blob Storage Lease Locking** built into the `azurerm` backend:
- The backend acquires and manages an exclusive blob lease on the target `.tfstate` blob.
- Eliminates the operational complexity, cost, and maintenance of external lock databases (e.g. DynamoDB or CosmosDB).

## Consequences
- Requires both `plan` and `apply` identities to possess `Storage Blob Data Contributor` on the state container to acquire and release blob leases.
- Native lease break capabilities available via Azure CLI if pipelines fail abruptly.

