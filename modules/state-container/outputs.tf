output "id" {
  description = "The Resource Manager ID of the storage container."
  value       = azurerm_storage_container.this.id
}

output "resource_manager_id" {
  description = "The Resource Manager ID of the storage container for scoping RBAC."
  value       = azurerm_storage_container.this.id
}

output "name" {
  description = "The name of the storage container."
  value       = azurerm_storage_container.this.name
}
