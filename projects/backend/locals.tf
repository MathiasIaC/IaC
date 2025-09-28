locals {
  resource_group_name    = "rg-${var.name_prefix}"
  storage_account_name   = "st${var.name_prefix}${var.unique_suffix}" # må være globalt unikt
  storage_container_name = "${var.name_prefix}-tfstate"
  container_name         = var.container_name
  kv_name                = var.kv_name

  # Principals to grant roles to
  principals = toset(
    concat(
      var.extra_principal_ids,
      var.assign_current_user ? [data.azurerm_client_config.current.object_id] : []
    )
  )
}