variable "zone_name" {
  type        = string
  default     = "privatelink.blob.core.windows.net"
  description = "Name of the Private DNS Zone (privatelink.blob.core.windows.net)."
}

variable "resource_group_name" {
  type        = string
  description = "Resource Group where the Private DNS Zone is hosted."
}

variable "virtual_network_ids" {
  type        = list(string)
  default     = []
  description = "List of Virtual Network IDs to link with this Private DNS Zone."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to the Private DNS Zone."
}
