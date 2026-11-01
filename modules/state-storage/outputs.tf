output "id" {
  description = "The ID of the storage account."
  value       = azurerm_storage_account.this.id
}

output "name" {
  description = "The name of the storage account."
  value       = azurerm_storage_account.this.name
}

output "primary_blob_endpoint" {
  description = "The primary blob service endpoint URL."
  value       = azurerm_storage_account.this.primary_blob_endpoint
}

output "primary_blob_host" {
  description = "The hostname of the primary blob service."
  value       = azurerm_storage_account.this.primary_blob_host
}

output "primary_access_key" {
  description = "The primary access key (sensitive). Used only during phase 1 bootstrap if Entra auth is not yet established."
  value       = azurerm_storage_account.this.primary_access_key
  sensitive   = true
}
