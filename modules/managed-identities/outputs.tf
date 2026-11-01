output "id" {
  description = "Resource ID of the User-Assigned Managed Identity."
  value       = azurerm_user_assigned_identity.this.id
}

output "principal_id" {
  description = "Principal ID (Object ID) of the User-Assigned Managed Identity."
  value       = azurerm_user_assigned_identity.this.principal_id
}

output "client_id" {
  description = "Client ID of the User-Assigned Managed Identity."
  value       = azurerm_user_assigned_identity.this.client_id
}

output "tenant_id" {
  description = "Tenant ID associated with the User-Assigned Managed Identity."
  value       = azurerm_user_assigned_identity.this.tenant_id
}
