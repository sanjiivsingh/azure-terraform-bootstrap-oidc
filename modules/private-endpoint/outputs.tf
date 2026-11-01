output "id" {
  description = "The ID of the Private Endpoint."
  value       = azurerm_private_endpoint.this.id
}

output "private_ip_address" {
  description = "The private IP address allocated to this endpoint."
  value       = length(azurerm_private_endpoint.this.custom_dns_configs) > 0 ? azurerm_private_endpoint.this.custom_dns_configs[0].ip_addresses[0] : null
}
