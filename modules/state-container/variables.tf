variable "container_name" {
  type        = string
  default     = "tfstate"
  description = "Name of the storage container dedicated to Terraform remote state."

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]{1,61}[a-z0-9])?$", var.container_name))
    error_message = "Container name must be 3-63 characters, lowercase alphanumeric and hyphens."
  }
}

variable "storage_account_id" {
  type        = string
  description = "Resource ID of the Azure Storage Account where the container will be hosted."
}
