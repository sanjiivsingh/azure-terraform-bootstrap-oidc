variable "storage_account_name" {
  type        = string
  description = "Globally unique name for the Azure Storage Account."

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "Storage account name must be between 3 and 24 characters, lowercase alphanumeric only."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group containing the storage account."
}

variable "location" {
  type        = string
  description = "Azure region where the storage account is deployed."
}

variable "account_tier" {
  type        = string
  default     = "Standard"
  description = "Tier of the storage account (Standard or Premium)."

  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "Storage account tier must be either 'Standard' or 'Premium'."
  }
}

variable "account_replication_type" {
  type        = string
  default     = "LRS"
  description = "Replication strategy for remote state storage (LRS, ZRS, GRS, GZRS)."

  validation {
    condition     = contains(["LRS", "ZRS", "GRS", "GZRS"], var.account_replication_type)
    error_message = "Replication type must be one of: LRS, ZRS, GRS, GZRS."
  }
}

variable "blob_soft_delete_retention_days" {
  type        = number
  default     = 30
  description = "Retention period in days for soft-deleted blobs (prevents accidental state loss)."

  validation {
    condition     = var.blob_soft_delete_retention_days >= 7 && var.blob_soft_delete_retention_days <= 365
    error_message = "Soft delete retention days must be between 7 and 365 days."
  }
}

variable "container_soft_delete_retention_days" {
  type        = number
  default     = 30
  description = "Retention period in days for soft-deleted containers."

  validation {
    condition     = var.container_soft_delete_retention_days >= 7 && var.container_soft_delete_retention_days <= 365
    error_message = "Container delete retention days must be between 7 and 365 days."
  }
}

variable "shared_access_key_enabled" {
  type        = bool
  default     = true
  description = "Whether storage account shared keys are enabled. Recommended to disable (false) once Entra ID auth is verified."
}

variable "public_network_access_enabled" {
  type        = bool
  default     = true
  description = "Whether public network access is allowed. Set to false after establishing private endpoint and self-hosted runners."
}

variable "network_rules" {
  type = object({
    default_action             = string
    ip_rules                   = optional(list(string), [])
    virtual_network_subnet_ids = optional(list(string), [])
    bypass                     = optional(list(string), ["AzureServices"])
  })
  default     = null
  description = "Optional network ACL rules restricting access to specified subnets or CIDRs."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Resource tags applied to the storage account."
}

