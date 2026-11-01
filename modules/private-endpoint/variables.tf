variable "name" {
  type        = string
  description = "Name of the Private Endpoint."
}

variable "resource_group_name" {
  type        = string
  description = "Resource Group for the Private Endpoint."
}

variable "location" {
  type        = string
  description = "Azure region for the Private Endpoint."
}

variable "subnet_id" {
  type        = string
  description = "Resource ID of the subnet hosting the private endpoint network interface."
}

variable "storage_account_id" {
  type        = string
  description = "Resource ID of the target Azure Storage Account."
}

variable "subresource_names" {
  type        = list(string)
  default     = ["blob"]
  description = "Subresource names to target (e.g., ['blob'])."
}

variable "private_dns_zone_ids" {
  type        = list(string)
  default     = []
  description = "List of Private DNS Zone IDs for automatic DNS record registration."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to the Private Endpoint."
}
