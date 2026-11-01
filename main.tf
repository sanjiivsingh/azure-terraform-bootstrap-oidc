data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "bootstrap" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_storage_account" "tfstate" {
  name                            = "sttfstate${random_string.suffix.result}"
  resource_group_name             = azurerm_resource_group.bootstrap.name
  location                        = azurerm_resource_group.bootstrap.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false

  # Keep these enabled during migration. Disable only after every consumer
  # uses Entra data-plane auth and private endpoint connectivity is verified.
  shared_access_key_enabled       = var.shared_access_key_enabled
  public_network_access_enabled   = var.public_network_access_enabled

  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 30
    }
    container_delete_retention_policy {
      days = 30
    }
  }

  tags = var.tags
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}

locals {
  tfstate_container_scope = "${azurerm_storage_account.tfstate.id}/blobServices/default/containers/${azurerm_storage_container.tfstate.name}"
  landing_zone_scope_ids = {
    for environment in var.landing_zone_environments :
    environment => lookup(
      var.landing_zone_scope_ids,
      environment,
      "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
    )
  }
}

# LEGACY COMPATIBILITY:
# Keep the existing Entra application/federation while downstream repositories
# migrate to per-environment user-assigned managed identities.
resource "azuread_application" "github_actions" {
  display_name = "app-github-actions-${var.github_organization}"
}

resource "azuread_service_principal" "github_actions" {
  client_id = azuread_application.github_actions.client_id
}

resource "azuread_application_federated_identity_credential" "main_branch" {
  for_each = toset(var.github_repositories)

  application_id = azuread_application.github_actions.id
  display_name   = "${each.key}-main"
  description    = "Legacy OIDC federation for ${each.key} main branch deployments"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_organization}/${each.key}:ref:refs/heads/main"
}

resource "azuread_application_federated_identity_credential" "pr_branches" {
  for_each = toset(var.github_repositories)

  application_id = azuread_application.github_actions.id
  display_name   = "${each.key}-pr"
  description    = "Legacy OIDC federation for ${each.key} pull requests"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_organization}/${each.key}:pull_request"
}

resource "azurerm_role_assignment" "tfstate_blob_contributor" {
  scope                = local.tfstate_container_scope
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.github_actions.object_id
}

# Separate identities for each ALZ environment and operation.
resource "azurerm_user_assigned_identity" "alz_plan" {
  for_each            = toset(var.landing_zone_environments)
  name                = "id-alz-${each.key}-plan"
  resource_group_name = azurerm_resource_group.bootstrap.name
  location            = azurerm_resource_group.bootstrap.location
  tags                = var.tags
}

resource "azurerm_user_assigned_identity" "alz_apply" {
  for_each            = toset(var.landing_zone_environments)
  name                = "id-alz-${each.key}-apply"
  resource_group_name = azurerm_resource_group.bootstrap.name
  location            = azurerm_resource_group.bootstrap.location
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

# Terraform azurerm backend uses blob leases; both plan and apply identities
# therefore need Blob Data Contributor on the state container.
resource "azurerm_role_assignment" "alz_plan_state" {
  for_each             = toset(var.landing_zone_environments)
  scope                = local.tfstate_container_scope
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.alz_plan[each.key].principal_id
}

resource "azurerm_role_assignment" "alz_apply_state" {
  for_each             = toset(var.landing_zone_environments)
  scope                = local.tfstate_container_scope
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.alz_apply[each.key].principal_id
}

# The current ALZ root creates resource groups at subscription scope.
# Plan gets Reader; apply gets Contributor. Supply a different scope ID per
# environment in landing_zone_scope_ids when dev/prod use different subscriptions.
resource "azurerm_role_assignment" "alz_plan_reader" {
  for_each             = toset(var.landing_zone_environments)
  scope                = local.landing_zone_scope_ids[each.key]
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.alz_plan[each.key].principal_id
}

resource "azurerm_role_assignment" "alz_apply_contributor" {
  for_each             = toset(var.landing_zone_environments)
  scope                = local.landing_zone_scope_ids[each.key]
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.alz_apply[each.key].principal_id
}

# Optional Blob Private Endpoint. Keep disabled until a management VNet,
# dedicated PE subnet, and private DNS ownership are confirmed.
resource "azurerm_private_dns_zone" "blob" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = coalesce(var.private_dns_resource_group_name, azurerm_resource_group.bootstrap.name)
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
  count                 = var.enable_private_endpoint ? 1 : 0
  name                  = "link-${var.management_vnet_name}-blob"
  resource_group_name   = coalesce(var.private_dns_resource_group_name, azurerm_resource_group.bootstrap.name)
  private_dns_zone_name = azurerm_private_dns_zone.blob[0].name
  virtual_network_id    = var.management_vnet_id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_endpoint" "tfstate_blob" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "pe-${azurerm_storage_account.tfstate.name}-blob"
  location            = azurerm_resource_group.bootstrap.location
  resource_group_name = azurerm_resource_group.bootstrap.name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-${azurerm_storage_account.tfstate.name}-blob"
    private_connection_resource_id = azurerm_storage_account.tfstate.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "blob-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob[0].id]
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.blob]
}
