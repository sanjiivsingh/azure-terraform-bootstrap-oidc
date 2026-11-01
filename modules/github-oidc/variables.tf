variable "github_organization" {
  type        = string
  description = "GitHub organization or user account name."
}

variable "github_repositories" {
  type        = list(string)
  default     = []
  description = "List of downstream repositories that consume this bootstrap state and OIDC identities."
}

variable "bootstrap_repository_name" {
  type        = string
  default     = "azure-terraform-bootstrap-oidc"
  description = "Name of the bootstrap repository managing the state storage and identity infrastructure."
}

variable "bootstrap_admin_environment" {
  type        = string
  default     = "bootstrap-admin"
  description = "GitHub Environment name for privileged bootstrap administration."
}

variable "app_name_prefix" {
  type        = string
  default     = "app-gha"
  description = "Prefix for Microsoft Entra Application display names."
}

variable "create_environment_identities" {
  type        = bool
  default     = true
  description = "Whether to provision dedicated environment-scoped Entra applications (dev-plan, dev-apply, prod-plan, prod-apply)."
}

variable "enable_legacy_branch_credentials" {
  type        = bool
  default     = true
  description = "Whether to retain backward-compatible federated credentials for refs/heads/main and pull_request directly on the primary identity."
}
