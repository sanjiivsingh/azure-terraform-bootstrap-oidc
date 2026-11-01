variable "name" {
  type        = string
  description = "Name of the resource group."

  validation {
    condition     = length(var.name) > 0 && length(var.name) <= 90
    error_message = "Resource group name must be between 1 and 90 characters."
  }
}

variable "location" {
  type        = string
  description = "Azure region where the resource group will be created."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "A mapping of tags to assign to the resource group."
}

