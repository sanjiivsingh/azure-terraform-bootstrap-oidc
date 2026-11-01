data "azurerm_client_config" "current" {}

# ------------------------------------------------------------------------------
# 1. Resource Group Module
# ------------------------------------------------------------------------------

module "resource_group" {
  source = "./modules/resource-group"

  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# ------------------------------------------------------------------------------
# 2. Remote State Storage Account Module
# ------------------------------------------------------------------------------

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

locals {
  storage_account_name    = var.storage_account_name != null ? var.storage_account_name : "sttfstate${random_string.suffix.result}"
  tfstate_container_scope = "${module.state_storage.id}/blobServices/default/containers/${module.state_container.name}"
  landing_zone_scope_ids = {
    for env in var.landing_zone_environments :
    env => lookup(
      var.landing_zone_scope_ids,
      env,
      "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
    )
  }
}

module "state_storage" {
  source = "./modules/state-storage"

  storage_account_name          = local.storage_account_name
  resource_group_name           = module.resource_group.name
  location                      = module.resource_group.location
  account_replication_type      = var.account_replication_type
  shared_access_key_enabled     = var.shared_access_key_enabled
  public_network_access_enabled = var.public_network_access_enabled
  tags                          = var.tags
}

# ------------------------------------------------------------------------------
# 3. State Container Module
# ------------------------------------------------------------------------------

module "state_container" {
  source = "./modules/state-container"

  container_name     = "tfstate"
  storage_account_id = module.state_storage.id
}

# ------------------------------------------------------------------------------
# 4. Microsoft Entra OIDC Workload Identities Module
# ------------------------------------------------------------------------------

module "github_oidc" {
  source = "./modules/github-oidc"

  github_organization              = var.github_organization
  github_repositories              = var.github_repositories
  bootstrap_repository_name        = var.github_repository_bootstrap
  bootstrap_admin_environment      = var.bootstrap_admin_environment
  create_environment_identities    = var.create_environment_identities
  enable_legacy_branch_credentials = var.enable_legacy_branch_credentials
}

# ------------------------------------------------------------------------------
# 5. User-Assigned Managed Identities for Landing Zone Environments (UAMI)
# ------------------------------------------------------------------------------

resource "azurerm_user_assigned_identity" "alz_plan" {
  for_each            = toset(var.landing_zone_environments)
  name                = "id-alz-${each.key}-plan"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = var.tags
}

resource "azurerm_user_assigned_identity" "alz_apply" {
  for_each            = toset(var.landing_zone_environments)
  name                = "id-alz-${each.key}-apply"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = var.tags
}

resource "azurerm_federated_identity_credential" "alz_plan" {
  for_each = toset(var.landing_zone_environments)

  name                      = "github-alz-${each.key}-plan"
  user_assigned_identity_id = azurerm_user_assigned_identity.alz_plan[each.key].id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = "https://token.actions.githubusercontent.com"
  subject                   = "repo:${var.github_organization}/${var.landing_zone_repository}:environment:${each.key}-plan"
}

resource "azurerm_federated_identity_credential" "alz_apply" {
  for_each = toset(var.landing_zone_environments)

  name                      = "github-alz-${each.key}-apply"
  user_assigned_identity_id = azurerm_user_assigned_identity.alz_apply[each.key].id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = "https://token.actions.githubusercontent.com"
  subject                   = "repo:${var.github_organization}/${var.landing_zone_repository}:environment:${each.key}-apply"
}

# ------------------------------------------------------------------------------
# 6. Least-Privilege RBAC
# ------------------------------------------------------------------------------

locals {
  alz_plan_principals  = [for id in azurerm_user_assigned_identity.alz_plan : id.principal_id]
  alz_apply_principals = [for id in azurerm_user_assigned_identity.alz_apply : id.principal_id]

  all_state_principals = concat(
    [module.github_oidc.bootstrap_admin_principal_id],
    values(module.github_oidc.environment_principal_ids),
    local.alz_plan_principals,
    local.alz_apply_principals
  )

  alz_workload_roles = merge(
    {
      for env in var.landing_zone_environments :
      "alz-plan-reader-${env}" => {
        principal_id         = azurerm_user_assigned_identity.alz_plan[env].principal_id
        role_definition_name = "Reader"
        scope                = local.landing_zone_scope_ids[env]
      }
    },
    {
      for env in var.landing_zone_environments :
      "alz-apply-contributor-${env}" => {
        principal_id         = azurerm_user_assigned_identity.alz_apply[env].principal_id
        role_definition_name = "Contributor"
        scope                = local.landing_zone_scope_ids[env]
      }
    }
  )
}

module "rbac" {
  source = "./modules/rbac"

  state_container_scope        = module.state_container.id
  state_blob_data_contributors = local.all_state_principals
  workload_role_assignments    = local.alz_workload_roles
}

# ------------------------------------------------------------------------------
# 7. Optional Private DNS and Private Endpoint (Staged Network Hardening)
# ------------------------------------------------------------------------------

module "private_dns" {
  count  = var.enable_private_endpoint && var.management_vnet_id != null ? 1 : 0
  source = "./modules/private-dns"

  zone_name           = "privatelink.blob.core.windows.net"
  resource_group_name = coalesce(var.private_dns_resource_group_name, module.resource_group.name)
  virtual_network_ids = [var.management_vnet_id]
  vnet_link_name      = "link-${var.management_vnet_name}-blob"
  tags                = var.tags
}

module "private_endpoint" {
  count  = var.enable_private_endpoint && var.private_endpoint_subnet_id != null ? 1 : 0
  source = "./modules/private-endpoint"

  name                 = "pe-${module.state_storage.name}-blob"
  resource_group_name  = module.resource_group.name
  location             = module.resource_group.location
  subnet_id            = var.private_endpoint_subnet_id
  storage_account_id   = module.state_storage.id
  subresource_names    = ["blob"]
  private_dns_zone_ids = var.enable_private_endpoint && var.management_vnet_id != null ? [module.private_dns[0].id] : []
  tags                 = var.tags
}
