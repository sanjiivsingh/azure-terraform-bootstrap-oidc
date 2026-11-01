# Self-Hosted Azure Runner Architecture

## 1. Network Topology & Runner Placement

When remote state storage is secured behind Private Endpoints (`public_network_access_enabled = false`), standard GitHub-hosted runners (`ubuntu-latest`) can no longer reach Azure Blob Storage over the public internet.

To deploy infrastructure in this hardened zero-trust posture, self-hosted GitHub Actions runners must reside inside an Azure Virtual Network peered with or directly hosting the Blob Private Endpoint.

```mermaid
flowchart TD
    subgraph GitHubCloud["🐙 GitHub Cloud"]
        QUEUE["Workflow Job Queue"]
    end

    subgraph AzureVNet["🏢 Enterprise Azure Virtual Network"]
        subgraph RunnerSubnet["Runner Subnet (10.10.1.0/24)"]
            RUNNER["Self-Hosted Runner VM / Container App<br/>Labels: [self-hosted, linux, azure-private]"]
        end

        subgraph PrivateEndpointSubnet["Private Endpoint Subnet (10.10.2.0/24)"]
            PE["Blob Private Endpoint (NIC: 10.10.2.15)"]
        end

        subgraph PrivateDNS["Private DNS Zone"]
            ZONE["privatelink.blob.core.windows.net<br/>A Record: sttfstate.privatelink.blob.core.windows.net -> 10.10.2.15"]
        end
    end

    subgraph AzureStorage["💾 Azure Storage Account (Isolated)"]
        ST["sttfstate[suffix]<br/>public_network_access_enabled = false"]
    end

    RUNNER -->|Outbound HTTPS:443 Long Polling| QUEUE
    RUNNER -->|DNS Lookup via Azure VNet Resolver 168.63.129.16| ZONE
    RUNNER -->|Private State Traffic| PE
    PE -->|Private Link| ST
```

---

## 2. Network Connectivity Requirements

### Outbound Requirements
Self-hosted runners **never require inbound open ports**. Runners initiate outbound HTTPS (TCP 443) long-polling connections to GitHub:
- `github.com:443`
- `api.github.com:443`
- `*.actions.githubusercontent.com:443`
- `*.githubassets.com:443`

Outbound internet traffic can be routed through an Azure NAT Gateway or Azure Firewall with TLS inspection.

### Inbound Requirements
- **0 Inbound Ports Open:** No public IP addresses are assigned to runner network interfaces.

---

## 3. Runner Group Scoping & Security Boundaries

> [!WARNING]
> **Privilege Escalation Risk on Self-Hosted Runners:**
> Self-hosted runners maintain direct network access to private Azure control planes. Never allow untrusted pull requests from public fork repositories to execute on self-hosted private runners. A malicious PR could execute arbitrary bash commands inside your Azure virtual network.

### Governance Guardrails
1. **GitHub Runner Groups:** Place private runners in an Enterprise or Organization Runner Group restricted exclusively to selected, trusted repositories.
2. **Ephemeral Containers:** Use ephemeral runner containers (e.g. via Kubernetes Actions Runner Controller - ARC or Azure Container Apps jobs) so each job runs in a pristine environment and container instances terminate immediately after execution.
3. **Workflow Routing:** Direct workflows using specific labels:
   ```yaml
   runs-on: [self-hosted, linux, azure-private]
   ```
