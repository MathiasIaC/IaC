# Resource Group
resource "azurerm_resource_group" "main" {
  name     = local.rg_name
  location = var.location

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.project_name
    Owner       = var.owner
  }
}

# Storage Account
resource "azurerm_storage_account" "main" {
  name                = local.sa_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  
  account_tier             = var.storage_tier
  account_replication_type = var.replication_type
  
  min_tls_version           = "TLS1_2"

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    owner       = var.owner
  }
}

# Storage Container
resource "azurerm_storage_container" "demo" {
  name                  = local.sc_name
  storage_account_id   = azurerm_storage_account.main.id
  container_access_type = "private"
}
