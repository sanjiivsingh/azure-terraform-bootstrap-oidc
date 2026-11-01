resource "azurerm_storage_account" "this" {
  name                            = var.storage_account_name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_tier                    = var.account_tier
  account_replication_type        = var.account_replication_type
  account_kind                    = "StorageV2"
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = var.shared_access_key_enabled
  public_network_access_enabled   = var.public_network_access_enabled
  default_to_oauth_authentication = true

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = var.blob_soft_delete_retention_days
    }

    container_delete_retention_policy {
      days = var.container_soft_delete_retention_days
    }
  }

  network_rules {
    default_action             = var.public_network_access_enabled ? "Allow" : "Deny"
    ip_rules                   = var.network_rules != null ? var.network_rules.ip_rules : []
    virtual_network_subnet_ids = var.network_rules != null ? var.network_rules.virtual_network_subnet_ids : []
    bypass                     = ["AzureServices"]
  }

  tags = var.tags
}
