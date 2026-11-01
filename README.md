# Azure Terraform Bootstrap: Remote State, OIDC and Private Connectivity

This repository bootstraps the shared Azure Terraform state platform used by
`sanjiivsingh/azure-enterprise-landing-zone-terraform`.

## Capabilities
- Azure Storage Account and private Blob container for Terraform state.
- Blob versioning, soft delete, HTTPS-only and TLS 1.2.
- GitHub OIDC without long-lived client secrets.
- Separate user-assigned managed identities for ALZ dev/prod plan and apply.
- Container-scoped Blob Data Contributor for state access and lease locking.
- Optional Blob Private Endpoint and private DNS integration.
- Legacy Entra application retained temporarily for migration and protected bootstrap administration.

## Migration-safe defaults
The Storage Account retains public network access and shared-key access by
default. Do not disable either until all consumers use Entra data-plane auth and
the Azure self-hosted runner has proven private endpoint connectivity.

## Bootstrap prerequisites
The initial deployment requires an operator with:
- Contributor (or equivalent) to create the resource group, storage and UAMIs.
- User Access Administrator or Role Based Access Control Administrator to
  create RBAC role assignments.
- Application Administrator / Cloud Application Administrator to manage the
  Entra application and federated credentials.

The protected GitHub bootstrap workflow uses the legacy application. Grant it
the required resource and RBAC administration permissions before running it.
Avoid Owner unless your governance model specifically requires it.

## Initial deployment and state migration
The bootstrap cannot initially use a Storage Account it has not created.
1. Back up the current local Terraform state.
2. Run `terraform init -backend=false`, `terraform plan`, and apply using an
   appropriately privileged operator identity.
3. Capture outputs for resource group, Storage Account, container, tenant,
   subscription and ALZ UAMI client IDs.
4. Add the empty `backend "azurerm" {}` block (provided as `backend.tf`).
5. Run `terraform init -migrate-state` with the backend values from outputs.
6. Verify the state blob, `terraform state list`, and a no-change plan.
7. Configure the protected GitHub Environment `bootstrap-admin`; subsequent
   changes can use the manual bootstrap workflow.

Do not delete the local backup until remote state has been verified.

## ALZ GitHub Environments and OIDC subjects
Create these environments in `azure-enterprise-landing-zone-terraform`:
- `dev-plan`: `repo:sanjiivsingh/azure-enterprise-landing-zone-terraform:environment:dev-plan`
- `dev-apply`: `repo:sanjiivsingh/azure-enterprise-landing-zone-terraform:environment:dev-apply`
- `prod-plan`: `repo:sanjiivsingh/azure-enterprise-landing-zone-terraform:environment:prod-plan`
- `prod-apply`: `repo:sanjiivsingh/azure-enterprise-landing-zone-terraform:environment:prod-apply`

The bootstrap creates distinct plan/apply UAMIs for dev and prod. Both identities
receive Blob Data Contributor on the state container for backend state and
lease operations. Plan gets Reader on the target subscription; apply gets
Contributor because the current ALZ root creates resource groups and network
resources. Narrow apply permissions after resource groups are pre-created.

Set environment variables in each ALZ GitHub Environment:
- `AZURE_CLIENT_ID`: matching UAMI client ID from bootstrap outputs.
- `AZURE_TENANT_ID`: Entra tenant ID.
- `AZURE_SUBSCRIPTION_ID`: target subscription ID.
Set repository variables `TFSTATE_RESOURCE_GROUP` and
`TFSTATE_STORAGE_ACCOUNT` for backend initialization.

For the bootstrap repository, create protected environment `bootstrap-admin`
and set `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`,
`TFSTATE_RESOURCE_GROUP`, and `TFSTATE_STORAGE_ACCOUNT`. Its federated
subject is
`repo:sanjiivsingh/azure-terraform-bootstrap-oidc:environment:bootstrap-admin`.

## Private runner and Blob endpoint
A private-only Storage Account requires the runner to have VNet routing and
private DNS resolution for `<account>.blob.core.windows.net`. GitHub-hosted
runners cannot directly reach the private endpoint. Use an Azure self-hosted
runner inside the VNet linked to `privatelink.blob.core.windows.net`.

The optional private endpoint requires `enable_private_endpoint=true`,
`management_vnet_id`, `private_endpoint_subnet_id`, and
`management_vnet_name`. Keep public access enabled until the Azure runner
resolves the Blob FQDN to the private endpoint IP and `terraform init` works.

The ALZ repo currently creates the Hub VNet, but the first ALZ deployment must
happen before a runner can be placed in that VNet. Use an authorized operator
and temporary public Storage access for this first deployment, then install
the Azure runner and complete private networking before locking down Storage.

## Security and operations
- Protect `prod-apply` and `bootstrap-admin` with required reviewers.
- Restrict the self-hosted runner group to trusted repositories.
- Never run untrusted fork PR code on the private runner.
- Do not store runner registration tokens in Terraform variables or state.
- State files can contain secrets; restrict container access and enable recovery.
- Keep the legacy app and FICs until all downstream consumers have migrated;
  remove them in a separate reviewed change.

## Validation
```bash
terraform fmt -recursive
terraform init -backend=false
terraform validate
terraform plan
```

See `docs/INTEGRATION.md` for the end-to-end consumer setup.
