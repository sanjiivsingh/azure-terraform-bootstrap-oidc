# ------------------------------------------------------------------------------
# 1. Bootstrap Admin Identity (Manages Remote State & Bootstrap Resources)
# ------------------------------------------------------------------------------

resource "azuread_application" "bootstrap_admin" {
  display_name = "${var.app_name_prefix}-${var.github_organization}-bootstrap-admin"
  description  = "Entra application for GitHub Actions managing Terraform remote state and identity bootstrap."
}

resource "azuread_service_principal" "bootstrap_admin" {
  client_id = azuread_application.bootstrap_admin.client_id
}

resource "azuread_application_federated_identity_credential" "bootstrap_main" {
  application_id = azuread_application.bootstrap_admin.id
  display_name   = "${var.bootstrap_repository_name}-main"
  description    = "OIDC federation for bootstrap repository main branch"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_organization}/${var.bootstrap_repository_name}:ref:refs/heads/main"
}

resource "azuread_application_federated_identity_credential" "bootstrap_pr" {
  application_id = azuread_application.bootstrap_admin.id
  display_name   = "${var.bootstrap_repository_name}-pr"
  description    = "OIDC federation for bootstrap repository pull requests"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_organization}/${var.bootstrap_repository_name}:pull_request"
}

resource "azuread_application_federated_identity_credential" "bootstrap_env" {
  application_id = azuread_application.bootstrap_admin.id
  display_name   = "${var.bootstrap_repository_name}-admin-env"
  description    = "OIDC federation for bootstrap repository environment ${var.bootstrap_admin_environment}"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_organization}/${var.bootstrap_repository_name}:environment:${var.bootstrap_admin_environment}"
}

# ------------------------------------------------------------------------------
# Backward Compatibility: Legacy Branch Credentials on Primary Identity
# ------------------------------------------------------------------------------

resource "azuread_application_federated_identity_credential" "legacy_main" {
  for_each = var.enable_legacy_branch_credentials ? toset(var.github_repositories) : toset([])

  application_id = azuread_application.bootstrap_admin.id
  display_name   = "legacy-${each.key}-main"
  description    = "Legacy OIDC federation for ${each.key} main branch"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_organization}/${each.key}:ref:refs/heads/main"
}

resource "azuread_application_federated_identity_credential" "legacy_pr" {
  for_each = var.enable_legacy_branch_credentials ? toset(var.github_repositories) : toset([])

  application_id = azuread_application.bootstrap_admin.id
  display_name   = "legacy-${each.key}-pr"
  description    = "Legacy OIDC federation for ${each.key} pull requests"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_organization}/${each.key}:pull_request"
}

# ------------------------------------------------------------------------------
# 2. Environment-Scoped Workload Identities (Dev Plan, Dev Apply, Prod Plan, Prod Apply)
# ------------------------------------------------------------------------------

locals {
  env_tiers = var.create_environment_identities ? {
    "dev-plan" = {
      description = "Identity for executing Terraform plan in development environments and PR checks"
      env_subject = "environment:dev-plan"
      allow_pr    = true
    }
    "dev-apply" = {
      description = "Identity for executing Terraform apply in development environments"
      env_subject = "environment:dev-apply"
      allow_pr    = false
    }
    "prod-plan" = {
      description = "Identity for executing Terraform plan in production environments"
      env_subject = "environment:prod-plan"
      allow_pr    = false
    }
    "prod-apply" = {
      description = "Identity for executing Terraform apply in production environments upon approval"
      env_subject = "environment:prod-apply"
      allow_pr    = false
    }
  } : {}

  # Flatten repository x environment mappings
  repo_env_pairs = {
    for pair in flatten([
      for env_key, env_data in local.env_tiers : [
        for repo in var.github_repositories : {
          key         = "${env_key}-${repo}"
          env_key     = env_key
          repo        = repo
          env_subject = env_data.env_subject
          allow_pr    = env_data.allow_pr
        }
      ]
    ]) : pair.key => pair
  }

  # Flatten repository x PR mappings for dev-plan
  repo_pr_pairs = {
    for pair in flatten([
      for env_key, env_data in local.env_tiers : [
        for repo in var.github_repositories : {
          key     = "${env_key}-${repo}-pr"
          env_key = env_key
          repo    = repo
        } if env_data.allow_pr
      ]
    ]) : pair.key => pair
  }
}

resource "azuread_application" "env_workload" {
  for_each = local.env_tiers

  display_name = "${var.app_name_prefix}-${var.github_organization}-${each.key}"
  description  = each.value.description
}

resource "azuread_service_principal" "env_workload" {
  for_each = local.env_tiers

  client_id = azuread_application.env_workload[each.key].client_id
}

resource "azuread_application_federated_identity_credential" "env_workload_env" {
  for_each = local.repo_env_pairs

  application_id = azuread_application.env_workload[each.value.env_key].id
  display_name   = "${each.value.repo}-${each.value.env_key}"
  description    = "Federated credential for ${each.value.repo} (${each.value.env_key})"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_organization}/${each.value.repo}:${each.value.env_subject}"
}

resource "azuread_application_federated_identity_credential" "env_workload_pr" {
  for_each = local.repo_pr_pairs

  application_id = azuread_application.env_workload[each.value.env_key].id
  display_name   = "${each.value.repo}-${each.value.env_key}-pr"
  description    = "Federated PR credential for ${each.value.repo} (${each.value.env_key})"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_organization}/${each.value.repo}:pull_request"
}
