data "azurerm_client_config" "current" {}

# ------------------------------------------------------------------------------
# 1. Resource Group
# ------------------------------------------------------------------------------

module "resource_group" {
  source = "../../modules/resource-group"

  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# ------------------------------------------------------------------------------
# 2. Remote State Storage Account
# ------------------------------------------------------------------------------

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

locals {
  storage_account_name = var.storage_account_name != null ? var.storage_account_name : "sttfstate${random_string.suffix.result}"
}

module "state_storage" {
  source = "../../modules/state-storage"

  storage_account_name          = local.storage_account_name
  resource_group_name           = module.resource_group.name
  location                      = module.resource_group.location
  account_replication_type      = var.account_replication_type
  shared_access_key_enabled     = var.shared_access_key_enabled
  public_network_access_enabled = var.public_network_access_enabled
  tags                          = var.tags
}

# ------------------------------------------------------------------------------
# 3. State Container
# ------------------------------------------------------------------------------

module "state_container" {
  source = "../../modules/state-container"

  container_name     = "tfstate"
  storage_account_id = module.state_storage.id
}

# ------------------------------------------------------------------------------
# 4. Microsoft Entra OIDC Workload Identities
# ------------------------------------------------------------------------------

module "github_oidc" {
  source = "../../modules/github-oidc"

  github_organization              = var.github_organization
  github_repositories              = var.github_repositories
  bootstrap_repository_name        = var.bootstrap_repository_name
  create_environment_identities    = var.create_environment_identities
  enable_legacy_branch_credentials = var.enable_legacy_branch_credentials
}

# ------------------------------------------------------------------------------
# 5. Optional User-Assigned Managed Identity
# ------------------------------------------------------------------------------

module "managed_identity" {
  count  = var.enable_managed_identity ? 1 : 0
  source = "../../modules/managed-identities"

  name                = "uami-terraform-${var.environment}"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = var.tags

  federated_credentials = {
    "bootstrap-runner" = {
      subject  = "repo:${var.github_organization}/${var.bootstrap_repository_name}:ref:refs/heads/main"
      audience = ["api://AzureADTokenExchange"]
      issuer   = "https://token.actions.githubusercontent.com"
    }
  }
}

# ------------------------------------------------------------------------------
# 6. Least-Privilege RBAC
# Assigns Storage Blob Data Contributor at the dedicated state container scope.
# ------------------------------------------------------------------------------

locals {
  all_state_principals = concat(
    [module.github_oidc.bootstrap_admin_principal_id],
    values(module.github_oidc.environment_principal_ids),
    var.enable_managed_identity ? [module.managed_identity[0].principal_id] : []
  )
}

module "rbac" {
  source = "../../modules/rbac"

  state_container_scope        = module.state_container.resource_manager_id
  state_blob_data_contributors = local.all_state_principals

  # Example workload role assignments (customize per target environment scopes)
  workload_role_assignments = {}
}

# ------------------------------------------------------------------------------
# 7. Optional Private DNS and Private Endpoint (Staged Network Hardening)
# ------------------------------------------------------------------------------

module "private_dns" {
  count  = var.enable_private_networking && var.virtual_network_id != null ? 1 : 0
  source = "../../modules/private-dns"

  resource_group_name = module.resource_group.name
  virtual_network_ids = [var.virtual_network_id]
  tags                = var.tags
}

module "private_endpoint" {
  count  = var.enable_private_networking && var.subnet_id != null ? 1 : 0
  source = "../../modules/private-endpoint"

  name                 = "pe-${module.state_storage.name}-blob"
  resource_group_name  = module.resource_group.name
  location             = module.resource_group.location
  subnet_id            = var.subnet_id
  storage_account_id   = module.state_storage.id
  subresource_names    = ["blob"]
  private_dns_zone_ids = var.enable_private_networking && var.virtual_network_id != null ? [module.private_dns[0].id] : []
  tags                 = var.tags
}
