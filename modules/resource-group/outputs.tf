output "id" {
  description = "The ID of the Resource Group."
  value       = azurerm_resource_group.this.id
}

output "name" {
  description = "The name of the Resource Group."
  value       = azurerm_resource_group.this.name
}

output "location" {
  description = "The Azure region of the Resource Group."
  value       = azurerm_resource_group.this.location
}
