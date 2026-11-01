output "state_role_assignment_ids" {
  description = "Resource IDs of the Storage Blob Data Contributor role assignments."
  value = {
    for k, v in azurerm_role_assignment.state_blob_contributor : k => v.id
  }
}

output "workload_role_assignment_ids" {
  description = "Resource IDs of workload-specific role assignments."
  value = {
    for k, v in azurerm_role_assignment.workload_roles : k => v.id
  }
}

