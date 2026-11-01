variable "state_container_scope" {
  type        = string
  description = "The Resource Manager scope of the state container (or storage account) for state blob RBAC."
}

variable "state_blob_data_contributors" {
  type        = list(string)
  default     = []
  description = "List of Principal (Object) IDs granted 'Storage Blob Data Contributor' at the state container scope."
}

variable "workload_role_assignments" {
  type = map(object({
    principal_id         = string
    role_definition_name = string
    scope                = string
  }))
  default     = {}
  description = "Workload-level least-privilege role assignments (e.g. Reader for plan identities, Contributor for apply identities on target RGs)."
}

