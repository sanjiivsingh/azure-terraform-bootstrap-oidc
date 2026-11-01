# ADR-003: Environment-Scoped Workload Identities vs. Monolithic Service Principal

## Status
Accepted

## Context
Deploying all environments (dev, prod, bootstrap) and all pipeline phases (plan, apply) under a single shared Service Principal creates an excessive blast radius. A compromised pull request or test workflow could compromise production state or deploy unapproved changes.

## Decision
Implement **Role- and Environment-Segregated Workload Identities**:
1. `bootstrap-admin`: Manages the state storage account and identity definitions.
2. `dev-plan`: Runs speculative plans on PRs and dev branches (Reader + State Blob Contributor).
3. `dev-apply`: Deploys infrastructure to dev (Dev Contributor + State Blob Contributor).
4. `prod-plan`: Runs speculative plans for production (Reader + State Blob Contributor).
5. `prod-apply`: Deploys to production guarded by GitHub Environment approvals (Prod Contributor + State Blob Contributor).

## Consequences
- Requires provisioning multiple Entra applications.
- Dramatically hardens least-privilege boundaries and guarantees production cannot be mutated from unauthorized pull requests.

