# ------------------------------------------------------------------------------
# State Container RBAC: Storage Blob Data Contributor
# Both plan and apply identities require blob data contributor on the state container
# because the azurerm backend acquires and manages blob lease locks during planning.
# ------------------------------------------------------------------------------

resource "azurerm_role_assignment" "state_blob_contributor" {
  for_each = toset(var.state_blob_data_contributors)

  scope                = var.state_container_scope
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = each.value
}

# ------------------------------------------------------------------------------
# Workload-Level RBAC: Granular Resource Group or Subscription Scopes
# ------------------------------------------------------------------------------

resource "azurerm_role_assignment" "workload_roles" {
  for_each = var.workload_role_assignments

  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.principal_id
}

