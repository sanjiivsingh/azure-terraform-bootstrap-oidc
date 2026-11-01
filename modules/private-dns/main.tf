resource "azurerm_private_dns_zone" "this" {
  name                = var.zone_name
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  count = length(var.virtual_network_ids)

  name                 = var.vnet_link_name != null ? var.vnet_link_name : "link-vnet-${count.index}"
  private_dns_zone_id  = azurerm_private_dns_zone.this.id
  virtual_network_id   = var.virtual_network_ids[count.index]
  registration_enabled = false
  tags                 = var.tags
}
