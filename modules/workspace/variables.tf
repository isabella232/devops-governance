data "azurerm_client_config" "current" {}

variable "name" {
  type        = string
  description = "Base name of your workspace that will be used in resource names. Please use lowercase with dashes"
}

variable "location" {
  type        = string
  description = "Azure Region for resources. Defaults to Western Europe."
  default     = "westeurope"
}

variable "client_tenant_id" {
  description = "AAD Tenant ID for Azure RM client (of current session)"
  type        = string
  default     = ""
}

variable "client_object_id" {
  description = "Object ID for Azure RM client (of current session)"
  type        = string
  default     = ""
}

locals {
  name             = lower(var.name)
  name_squished    = replace(local.name, "-", "")
  client_tenant_id = var.client_tenant_id == "" ? data.azurerm_client_config.current.tenant_id : var.client_tenant_id
  client_object_id = var.client_object_id == "" ? data.azurerm_client_config.current.object_id : var.client_object_id
}
