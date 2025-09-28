variable "subscription_id" {
  description = "Azure subscription to deploy into. If omitted, provider will use CLI default subscription."
  type        = string
  default     = ""
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
}

variable "name_prefix" {
  description = "Short prefix for naming (e.g. course or class code). Lowercase letters and digits only."
  type        = string
}

variable "unique_suffix" {
  description = "Unique, short suffix to ensure global-unique names (letters/digits). Leave empty to auto-generate."
  type        = string
}

variable "container_name" {
  description = "Blob container name for Terraform state. Defined in terraform.tfvars"
  type        = string
}

variable "kv_name" {
  description = "Key Vault name. Defined in terraform.tfvars"
  type        = string
}

variable "kv_sku_name" {
  description = "Key Vault SKU."
  type        = string
  default     = "standard"
}

variable "assign_current_user" {
  description = "Whether to assign RBAC roles to the currently logged-in user."
  type        = bool
  default     = true
}

variable "extra_principal_ids" {
  description = "Optional list of AAD object IDs (e.g. App Registrations / Service Principals) to grant RBAC on SA container and Key Vault."
  type        = list(string)
}

variable "tags" {
  description = "Common tags for all resources."
  type        = map(string)
  default = {
    purpose   = "tf-backend"
    lifecycle = "platform"
    cleanup   = "exclude"
  }
}