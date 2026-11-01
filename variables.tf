variable "resource_group_name" {
  type        = string
  default     = "rg-terraform-bootstrap"
  description = "Resource group holding Terraform state and bootstrap identity resources."
}

variable "location" {
  type        = string
  default     = "centralindia"
  description = "Azure region for bootstrap resources."
}

variable "github_organization" {
  type        = string
  default     = "sanjiivsingh"
  description = "GitHub owner used in OIDC subject claims."
}

variable "github_repositories" {
  type        = list(string)
  default     = [
    "azure-enterprise-landing-zone-terraform",
    "azure-enterprise-ai-landing-zone-terraform",
    "azure-aks-devsecops-pipeline",
    "azure-landing-zone-governance"
  ]
  description = "Legacy repositories retained during OIDC identity migration."
}

variable "github_repository_bootstrap" {
  type        = string
  default     = "azure-terraform-bootstrap-oidc"
  description = "Bootstrap repository name for privileged environment OIDC."
}

variable "landing_zone_repository" {
  type        = string
  default     = "azure-enterprise-landing-zone-terraform"
  description = "Repository receiving environment-scoped ALZ OIDC identities."
}

variable "landing_zone_environments" {
  type        = set(string)
  default     = ["dev", "prod"]
  description = "GitHub deployment environments for which separate plan/apply identities are created."
}

variable "landing_zone_scope_ids" {
  type        = map(string)
  default     = {}
  description = "Optional Azure scope per environment. Defaults to the current subscription. Example: { dev = \"/subscriptions/<dev-sub-id>\", prod = \"/subscriptions/<prod-sub-id>\" }."
}

variable "shared_access_key_enabled" {
  type        = bool
  default     = true
  description = "Keep enabled during migration. Disable after every backend consumer uses Entra ID auth."
}

variable "public_network_access_enabled" {
  type        = bool
  default     = true
  description = "Keep enabled until private runner connectivity and DNS have been verified."
}

variable "enable_private_endpoint" {
  type        = bool
  default     = false
  description = "Enable the Blob private endpoint only after providing the management VNet and PE subnet IDs."
}

variable "management_vnet_id" {
  type        = string
  default     = null
  description = "Management VNet ID linked to the Blob private DNS zone."
  nullable    = true
}

variable "management_vnet_name" {
  type        = string
  default     = "vnet-management"
  description = "Name used for the private DNS VNet link."
}

variable "private_endpoint_subnet_id" {
  type        = string
  default     = null
  description = "Dedicated subnet ID for the Blob private endpoint."
  nullable    = true
}

variable "private_dns_resource_group_name" {
  type        = string
  default     = null
  description = "Optional resource group for private DNS zone. Defaults to bootstrap RG."
  nullable    = true
}

variable "tags" {
  type        = map(string)
  default     = {
    ManagedBy   = "Terraform"
    Environment = "Bootstrap"
    Project     = "Azure-Platform-OIDC"
  }
  description = "Common resource tags."
}

variable "bootstrap_admin_environment" {
  type        = string
  default     = "bootstrap-admin"
  description = "GitHub Environment name for privileged bootstrap workflow federation."
}
