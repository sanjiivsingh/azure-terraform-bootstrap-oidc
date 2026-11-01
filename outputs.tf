output "resource_group_name" {
  description = "Resource Group holding Terraform remote state."
  value       = azurerm_resource_group.bootstrap.name
}

output "storage_account_name" {
  description = "Storage Account name for azurerm backend configuration."
  value       = azurerm_storage_account.tfstate.name
}

output "container_name" {
  description = "Private state container name."
  value       = azurerm_storage_container.tfstate.name
}

output "azure_client_id" {
  description = "Legacy bootstrap Entra application client ID. Retain only for bootstrap migration."
  value       = azuread_application.github_actions.client_id
}

output "azure_tenant_id" {
  description = "Microsoft Entra tenant ID."
  value       = data.azurerm_client_config.current.tenant_id
}

output "azure_subscription_id" {
  description = "Subscription used by this bootstrap deployment."
  value       = data.azurerm_client_config.current.subscription_id
}

output "alz_plan_client_ids" {
  description = "Client IDs for ALZ plan identities, keyed by environment."
  value       = { for env, identity in azurerm_user_assigned_identity.alz_plan : env => identity.client_id }
}

output "alz_apply_client_ids" {
  description = "Client IDs for ALZ apply identities, keyed by environment."
  value       = { for env, identity in azurerm_user_assigned_identity.alz_apply : env => identity.client_id }
}

output "tfstate_container_resource_id" {
  description = "Container resource ID for least-privilege Blob RBAC assignments."
  value       = local.tfstate_container_scope
}

output "blob_private_endpoint_ip" {
  description = "Private endpoint IP when private endpoint is enabled."
  value       = try(azurerm_private_endpoint.tfstate_blob[0].private_service_connection[0].private_ip_address, null)
}
