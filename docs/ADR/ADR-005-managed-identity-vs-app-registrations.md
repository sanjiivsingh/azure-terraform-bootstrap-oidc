# ADR-005: User-Assigned Managed Identity vs. App Registrations for Azure-Native Workloads

## Status
Accepted

## Context
While GitHub Actions hosted outside of Azure relies on Microsoft Entra App Registrations for Workload Identity Federation, self-hosted runners running natively inside Azure (on AKS, Azure Container Apps, or Azure VMs) can authenticate using User-Assigned Managed Identities (UAMI).

## Decision
Support **both patterns**:
1. Entra Application Registrations for standard GitHub-hosted and external runner federation.
2. User-Assigned Managed Identity (UAMI) module with federated identity credentials for Azure-native workloads and self-hosted runner infrastructure.

## Consequences
- Maximizes platform portability across both cloud-hosted and self-hosted runner models.

