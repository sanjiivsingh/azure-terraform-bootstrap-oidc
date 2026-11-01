# ADR-004: Staged Network Perimeter Migration for Remote State Storage

## Status
Accepted

## Context
Securing state storage with Private Endpoints and disabling public network access is the ultimate zero-trust pattern. However, attempting to enforce private-only access on initial deployment breaks the bootstrap deployment process because public runners and initial local migrations cannot reach private endpoints without existing VNet peering or VPN connectivity.

## Decision
Adopt a **4-Phase Staged Migration Pattern**:
- **Phase 1 (Bootstrap):** Storage deployed with public access over TLS 1.2+ and Entra ID OAuth enforcement.
- **Phase 2 (OIDC Validation):** Validate all downstream consumers authenticate via Entra tokens.
- **Phase 3 (Private Link):** Deploy Private Endpoint and Private DNS Zone linked to runner VNets.
- **Phase 4 (Hardening):** Verify self-hosted runner connectivity, then disable public network access (`public_network_access_enabled = false`) and disable shared keys (`shared_access_key_enabled = false`).

## Consequences
- Prevents deployment deadlocks during bootstrap while establishing a verified path to zero-trust network isolation.
