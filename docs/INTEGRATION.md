# Integration guide: Bootstrap backend + Azure Enterprise Landing Zone

## Backend state keys
Use one key per independent Terraform root:
- `landing-zone/dev.terraform.tfstate`
- `landing-zone/prod.terraform.tfstate`

Do not share state between environments or unrelated roots.

## ALZ environment root
The existing ALZ repo has its Terraform root under `environments/dev`.
Its backend uses the bootstrap outputs:
- resource group: bootstrap `resource_group_name`
- storage account: bootstrap `storage_account_name`
- container: `tfstate`
- key: `landing-zone/dev.terraform.tfstate`
- `use_oidc=true`
- `use_azuread_auth=true`

The backend and AzureRM provider authenticate separately. Set
`ARM_USE_OIDC=true`, `ARM_CLIENT_ID`, `ARM_TENANT_ID`, and
`ARM_SUBSCRIPTION_ID`. GitHub supplies the OIDC request URL and token when
`id-token: write` is granted.

## GitHub environments
Create `dev-plan`, `dev-apply`, `prod-plan`, and `prod-apply` in the ALZ
repository. Configure each environment's `AZURE_CLIENT_ID`,
`AZURE_TENANT_ID`, and `AZURE_SUBSCRIPTION_ID`. Client IDs must match the
corresponding UAMI output. Protect `prod-apply` with required reviewers and
restrict deployments to the main branch.

The plan and apply identities are distinct. Both need Blob Data Contributor on
the state container for state operations and leases. Plan receives Reader on
the workload subscription. Apply receives Contributor at subscription scope
because the current ALZ root creates resource groups; reduce this after
pre-creating resource groups and using resource-group-scoped assignments.

## Network and runner rollout
The current ALZ creates its Hub VNet. First deploy it using an authorized
operator while bootstrap Storage public access remains enabled. Then deploy a
dedicated runner subnet and Azure Linux VM, register a GitHub self-hosted
runner using a short-lived token, and verify private DNS and Blob access.
Switch workflow jobs to labels `[self-hosted, linux, azure-private]`.
Only then disable public network access and shared-key access.

Do not use a privileged private runner for fork pull requests. CI formatting,
validation and security scans run on GitHub-hosted runners without Azure
credentials.
