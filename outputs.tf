output "resource_group_name" {
  description = "Resource Group holding Terraform remote state."
  value       = module.resource_group.name
}

output "storage_account_name" {
  description = "Storage Account name for azurerm backend configuration."
  value       = module.state_storage.name
}

output "storage_account_id" {
  description = "Resource ID of the storage account."
  value       = module.state_storage.id
}

output "container_name" {
  description = "Private state container name."
  value       = module.state_container.name
}

output "azure_client_id" {
  description = "Legacy bootstrap Entra application client ID. Retain only for bootstrap migration."
  value       = module.github_oidc.bootstrap_admin_client_id
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
  description = "Microsoft Entra directory (tenant) ID."
  value       = data.azurerm_client_config.current.tenant_id
}

output "azure_subscription_id" {
  description = "Subscription used by this bootstrap deployment."
  value       = data.azurerm_client_config.current.subscription_id
}

output "alz_plan_client_ids" {
  description = "Client IDs for ALZ plan identities, keyed by environment."
  value       = { for env, identity in azurerm_user_assigned_identity.alz_plan : env => identity.client_id }
}

output "alz_apply_client_ids" {
  description = "Client IDs for ALZ apply identities, keyed by environment."
  value       = { for env, identity in azurerm_user_assigned_identity.alz_apply : env => identity.client_id }
}

output "tfstate_container_resource_id" {
  description = "Container resource ID for least-privilege Blob RBAC assignments."
  value       = local.tfstate_container_scope
}

output "blob_private_endpoint_ip" {
  description = "Private endpoint IP when private endpoint is enabled."
  value       = var.enable_private_endpoint && var.private_endpoint_subnet_id != null ? module.private_endpoint[0].private_ip_address : null
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
