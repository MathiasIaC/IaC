variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string
  
  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Environment must be dev, test, or prod."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "westeurope"
}

variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
  default     = "oblig2"
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "mk"
}

variable "suffix" {
  description = "Random suffix for resource names"
  type        = string
  default     = "dut"
}

variable "storage_tier" {
  description = "Storage tier for the storage account"
  type        = string
  default     = "Standard"
}

variable "replication_type" {
  description = "Replication type for the storage account"
  type        = string
  default     = "LRS"
}

