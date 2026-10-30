output "resource_group_name" {
  description = "Resource Group holding the Terraform remote state storage account."
  value       = azurerm_resource_group.bootstrap.name
}

output "storage_account_name" {
  description = "Storage Account name for configuring azurerm backend blocks."
  value       = azurerm_storage_account.tfstate.name
}

output "container_name" {
  description = "Storage container name for tfstate blobs."
  value       = azurerm_storage_container.tfstate.name
}

output "azure_client_id" {
  description = "Microsoft Entra Application (Client) ID for GitHub Actions OIDC."
  value       = azuread_application.github_actions.client_id
}

output "azure_tenant_id" {
  description = "Microsoft Entra Directory (Tenant) ID."
  value       = data.azurerm_client_config.current.tenant_id
}

output "azure_subscription_id" {
  description = "Target Azure Subscription ID."
  value       = data.azurerm_client_config.current.subscription_id
}

