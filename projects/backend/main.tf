terraform {
  required_version = ">= 1.6.0"

 backend "azurerm" {
   # Må ha med backend blokk for å kunne migrere state til azurerm
  } 


  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.40.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  use_cli         = true
}

# Logged-in context (user/service principal via az login)
data "azurerm_client_config" "current" {
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = local.resource_group_name
  location = var.location
  tags     = var.tags
}

# Storage Account for Terraform state
resource "azurerm_storage_account" "sa" {
  name                     = local.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Hardening / good practice
  allow_nested_items_to_be_public = false
  min_tls_version                 = "TLS1_2"
  # shared_access_key_enabled = false <-- Set to false after bootstrap
  shared_access_key_enabled       = true # tillat nøkler ved bootstrap
  https_traffic_only_enabled      = true
  default_to_oauth_authentication = true

  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 14
    }
    container_delete_retention_policy {
      days = 14
    }
    change_feed_enabled = true
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# Private container for state
resource "azurerm_storage_container" "state" {
  name                  = local.container_name
  storage_account_id    = azurerm_storage_account.sa.id
  container_access_type = "private"
}

# Key Vault (RBAC-enabled)
resource "azurerm_key_vault" "kv" {
  name                       = local.kv_name
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = var.kv_sku_name
  soft_delete_retention_days = 90
  purge_protection_enabled   = true

  # Network rules can be tightened later in exercises
  public_network_access_enabled = true
  # "enable_rbac_authorization" is deprecated and no longer required in recent provider versions.
  # RBAC is enabled by default for new Key Vaults.
  tags = var.tags
}

# --------- RBAC ASSIGNMENTS ---------
# Storage: give principals Blob Data Contributor on the *container* (scope must be container or SA).
resource "azurerm_role_assignment" "sa_blob_contributor" {
  for_each             = local.principals
  scope                = azurerm_storage_account.sa.id # for container, use azurerm_storage_container.state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = each.key
  depends_on           = [azurerm_storage_container.state]
}

# (Optional) SA Reader at account scope for portal listing (nice-to-have)
resource "azurerm_role_assignment" "sa_reader" {
  for_each             = local.principals
  scope                = azurerm_storage_account.sa.id
  role_definition_name = "Reader"
  principal_id         = each.key
  depends_on           = [azurerm_storage_account.sa]
}

# Key Vault: grant Secrets Officer (read/write). Use Secrets User if read-only is preferred.
resource "azurerm_role_assignment" "kv_secrets_officer" {
  for_each             = local.principals
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = each.key
  depends_on           = [azurerm_key_vault.kv]
}
