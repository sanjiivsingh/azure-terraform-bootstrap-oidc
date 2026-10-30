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

variable "github_organization" {
  type        = string
  default     = "sanjiivsingh"
  description = "GitHub username or organization name for OIDC subject claims."
}

variable "github_repositories" {
  type        = list(string)
  default     = [
    "azure-enterprise-landing-zone-terraform",
    "azure-enterprise-ai-landing-zone-terraform",
    "azure-aks-devsecops-pipeline",
    "azure-landing-zone-governance"
  ]
  description = "List of repository names granted federated OIDC credentials."
}

variable "tags" {
  type        = map(string)
  default     = {
    ManagedBy   = "Terraform"
    Environment = "Bootstrap"
    Project     = "Azure-Platform-OIDC"
  }
}

