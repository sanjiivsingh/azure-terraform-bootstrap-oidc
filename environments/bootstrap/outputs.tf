output "resource_group_name" {
  description = "Resource Group holding the Terraform remote state storage account."
  value       = module.resource_group.name
}

output "storage_account_name" {
  description = "Storage Account name for configuring azurerm backend blocks."
  value       = module.state_storage.name
}

output "storage_account_id" {
  description = "Resource ID of the storage account."
  value       = module.state_storage.id
}

output "container_name" {
  description = "Storage container name for tfstate blobs."
  value       = module.state_container.name
}

output "container_resource_manager_id" {
  description = "Resource Manager ID of the container used for granular RBAC scoping."
  value       = module.state_container.resource_manager_id
}

output "bootstrap_admin_client_id" {
  description = "Microsoft Entra Application (Client) ID for bootstrap administration."
  value       = module.github_oidc.bootstrap_admin_client_id
}

output "environment_client_ids" {
  description = "Map of environment names (dev-plan, dev-apply, prod-plan, prod-apply) to their Entra Application Client IDs."
  value       = module.github_oidc.environment_client_ids
}

output "azure_tenant_id" {
  description = "Microsoft Entra Directory (Tenant) ID."
  value       = data.azurerm_client_config.current.tenant_id
}

output "azure_subscription_id" {
  description = "Target Azure Subscription ID."
  value       = data.azurerm_client_config.current.subscription_id
}

output "managed_identity_client_id" {
  description = "Client ID of the User-Assigned Managed Identity (if enabled)."
  value       = var.enable_managed_identity ? module.managed_identity[0].client_id : null
}

output "backend_config_snippet" {
  description = "Pre-configured HCL backend snippet for downstream repositories."
  value       = <<EOT
terraform {
  backend "azurerm" {
    resource_group_name  = "${module.resource_group.name}"
    storage_account_name = "${module.state_storage.name}"
    container_name       = "${module.state_container.name}"
    key                  = "<workload-name>/<environment>.terraform.tfstate"
    use_oidc             = true
  }
}
EOT
}

