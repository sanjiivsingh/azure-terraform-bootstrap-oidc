# ------------------------------------------------------------------------------
# Remote State Backend Configuration
# ------------------------------------------------------------------------------
# Architectural Note:
# During phase 1 initial deployment, this block is commented out because Terraform
# cannot use a remote storage account before creating it.
# Once 'terraform apply' completes, uncomment the backend block below and execute:
#   terraform init -migrate-state
# ------------------------------------------------------------------------------

terraform {
  # backend "azurerm" {
  #   resource_group_name  = "rg-terraform-bootstrap"
  #   storage_account_name = "<OUTPUT_STORAGE_ACCOUNT_NAME>"
  #   container_name       = "tfstate"
  #   key                  = "bootstrap/terraform.tfstate"
  #   use_oidc             = true
  # }
}

