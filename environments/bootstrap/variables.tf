variable "resource_group_name" {
  type        = string
  default     = "rg-terraform-bootstrap"
  description = "Name of the resource group holding Terraform state and OIDC credentials."
}

variable "location" {
  type        = string
  default     = "centralindia"
  description = "Primary Azure region."
}

variable "environment" {
  type        = string
  default     = "bootstrap"
  description = "Environment identifier tag."
}

variable "storage_account_name" {
  type        = string
  default     = null
  description = "Optional custom storage account name. If null, a deterministic prefix with a random suffix is used."
}

variable "account_replication_type" {
  type        = string
  default     = "LRS"
  description = "Replication type for the state storage account (LRS, ZRS, GRS, GZRS)."
}

variable "shared_access_key_enabled" {
  type        = bool
  default     = true
  description = "Whether shared key auth is enabled. Switch to false once Entra ID RBAC is verified."
}

variable "public_network_access_enabled" {
  type        = bool
  default     = true
  description = "Whether public network access is allowed. Switch to false after private endpoint deployment."
}

variable "github_organization" {
  type        = string
  default     = "sanjiivsingh"
  description = "GitHub username or organization name for OIDC subject claims."
}

variable "github_repositories" {
  type = list(string)
  default = [
    "azure-enterprise-landing-zone-terraform",
    "azure-enterprise-ai-landing-zone-terraform",
    "azure-aks-devsecops-pipeline",
    "azure-landing-zone-governance"
  ]
  description = "List of downstream repository names granted federated OIDC credentials."
}

variable "bootstrap_repository_name" {
  type        = string
  default     = "azure-terraform-bootstrap-oidc"
  description = "Name of the bootstrap repository itself."
}

variable "create_environment_identities" {
  type        = bool
  default     = true
  description = "Whether to provision granular dev-plan, dev-apply, prod-plan, and prod-apply Entra applications."
}

variable "enable_legacy_branch_credentials" {
  type        = bool
  default     = true
  description = "Whether to retain backward-compatible federated credentials for refs/heads/main and pull_request directly on the primary identity."
}

variable "enable_managed_identity" {
  type        = bool
  default     = false
  description = "Whether to deploy a User-Assigned Managed Identity alongside Entra App Registrations."
}

variable "enable_private_networking" {
  type        = bool
  default     = false
  description = "Whether to provision Private Endpoint and Private DNS Zone for state storage."
}

variable "virtual_network_id" {
  type        = string
  default     = null
  description = "Resource ID of the Virtual Network to link with the Private DNS Zone (if enable_private_networking is true)."
}

variable "subnet_id" {
  type        = string
  default     = null
  description = "Resource ID of the subnet for the Blob Private Endpoint (if enable_private_networking is true)."
}

variable "tags" {
  type = map(string)
  default = {
    ManagedBy   = "Terraform"
    Environment = "Bootstrap"
    Project     = "Azure-Platform-OIDC"
  }
  description = "Common resource tags."
}
