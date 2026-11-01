variable "name" {
  type        = string
  description = "Name of the User-Assigned Managed Identity."
}

variable "resource_group_name" {
  type        = string
  description = "Resource Group where the Managed Identity resides."
}

variable "location" {
  type        = string
  description = "Azure region for the Managed Identity."
}

variable "federated_credentials" {
  type = map(object({
    subject  = string
    audience = optional(list(string), ["api://AzureADTokenExchange"])
    issuer   = optional(string, "https://token.actions.githubusercontent.com")
  }))
  default     = {}
  description = "Map of federated identity credentials to configure on this Managed Identity."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to the Managed Identity."
}
