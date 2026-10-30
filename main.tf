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
  name                     = "sttfstate${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.bootstrap.name
  location                 = azurerm_resource_group.bootstrap.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

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

# Microsoft Entra Application for GitHub Actions OIDC
resource "azuread_application" "github_actions" {
  display_name = "app-github-actions-${var.github_organization}"
}

resource "azuread_service_principal" "github_actions" {
  client_id = azuread_application.github_actions.client_id
}

# Federated Identity Credentials per Repository
resource "azuread_application_federated_identity_credential" "main_branch" {
  for_each = toset(var.github_repositories)

  application_id = azuread_application.github_actions.id
  display_name   = "${each.key}-main"
  description    = "OIDC federation for ${each.key} main branch deployments"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_organization}/${each.key}:ref:refs/heads/main"
}

resource "azuread_application_federated_identity_credential" "pr_branches" {
  for_each = toset(var.github_repositories)

  application_id = azuread_application.github_actions.id
  display_name   = "${each.key}-pr"
  description    = "OIDC federation for ${each.key} pull requests"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_organization}/${each.key}:pull_request"
}

# Least-privilege Storage Blob Data Contributor on State Container
resource "azurerm_role_assignment" "tfstate_blob_contributor" {
  scope                = azurerm_storage_account.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.github_actions.object_id
}

