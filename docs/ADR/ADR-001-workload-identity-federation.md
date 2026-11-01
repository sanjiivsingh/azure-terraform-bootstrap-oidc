# ADR-001: Microsoft Entra Workload Identity Federation (GitHub OIDC)

## Status
Accepted

## Context
Automating Terraform in GitHub Actions requires authenticating to Microsoft Azure. Traditional models store long-lived Service Principal client secrets (`ARM_CLIENT_SECRET`) within GitHub repository secrets. This exposes credentials to rotation overhead, potential exfiltration in logs, and outages when secrets expire.

## Decision
Adopt **Microsoft Entra Workload Identity Federation (OIDC)**:
1. Zero secrets stored in GitHub.
2. Short-lived tokens minted on-demand for specific repository and branch/environment contexts.
3. Cryptographically verified against GitHub's OpenID Connect issuer.

## Consequences
- Requires Entra ID permissions (`Application Administrator`) for initial provisioning.
- Eliminates secret rotation schedules and credential leakage risks.
