output "bootstrap_admin_client_id" {
  description = "Client ID of the bootstrap admin Entra application."
  value       = azuread_application.bootstrap_admin.client_id
}

output "bootstrap_admin_principal_id" {
  description = "Principal ID (Object ID) of the bootstrap admin service principal."
  value       = azuread_service_principal.bootstrap_admin.object_id
}

output "environment_client_ids" {
  description = "Map of environment names (dev-plan, dev-apply, prod-plan, prod-apply) to their Entra Application Client IDs."
  value = {
    for k, v in azuread_application.env_workload : k => v.client_id
  }
}

output "environment_principal_ids" {
  description = "Map of environment names to Service Principal Object IDs for RBAC assignments."
  value = {
    for k, v in azuread_service_principal.env_workload : k => v.object_id
  }
}

