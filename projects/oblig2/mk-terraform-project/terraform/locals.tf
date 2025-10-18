locals {
  rg_name = "rg-${var.owner}-${var.project_name}-${var.environment}"
  sa_name = "st${var.owner}${var.project_name}${var.environment}${var.suffix}"
  sc_name = "sc-${var.owner}-${var.project_name}-${var.environment}"
}