# RESOURCE GROUP
# --------------

resource "azurerm_resource_group" "rg" {
  name     = "${local.name}-rg"
  location = var.location
}

# STORAGE ACCOUNT
# ---------------

resource "azurerm_storage_account" "storage" {
  name                     = local.name_squished
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  allow_blob_public_access = false
}


# AZURE CONTAINER REGISTRY
# ------------------------

resource "azurerm_container_registry" "acr" {
  name                     = local.name_squished
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  sku                      = "Basic"
  admin_enabled            = false
}


# AZURE KEY VAULT
# ---------------

resource "azurerm_key_vault" "kv" {
  name                        = "${local.name_squished}-kv"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = local.client_tenant_id
  soft_delete_enabled         = false # so we don't leave anything behind
  purge_protection_enabled    = false # so we can fully delete it
  sku_name                    = "standard"
}

# Key Vault Access Policy - me

resource "azurerm_key_vault_access_policy" "me" {
  key_vault_id = azurerm_key_vault.kv.id
  object_id    = local.client_object_id
  tenant_id    = local.client_tenant_id

  secret_permissions = [
    "backup",
    "delete",
    "get",
    "list",
    "purge",
    "recover",
    "restore",
    "set"
  ]
}

# Key Vault Access Policy - Azure DevOps

resource "azurerm_key_vault_access_policy" "kv_reader" {
  key_vault_id = azurerm_key_vault.kv.id
  object_id    = azuread_application.kv_reader_sp.object_id
  tenant_id    = local.client_tenant_id

  key_permissions = [
    "get",
  ]

  secret_permissions = [
    "get",
  ]
}

# Key Vault - Example secrets

resource "azurerm_key_vault_secret" "example" {
  name         = "secret-sauce"
  value        = "szechuan"
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [
    azurerm_key_vault_access_policy.me
  ]
}

resource "azurerm_key_vault_secret" "demo_1" {
  name         = "kv-api-key"
  value        = "just-a-demo-never-do-this-irl"
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [
    azurerm_key_vault_access_policy.me
  ]
}

resource "azurerm_key_vault_secret" "demo_2" {
  name         = "kv-api-secret"
  value        = "just-a-demo-never-do-this-irl"
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [
    azurerm_key_vault_access_policy.me
  ]
}


# SERVICE_PRINCIPALS
# ------------------

# SP - Workspace (scoped to resource group)

resource "azuread_application" "rg_sp" {
  name = "${local.name}-rg-sp"

  depends_on = [
    azurerm_resource_group.rg
  ]
}

resource "azuread_application_password" "rg_sp_secret" {
  application_object_id = azuread_application.rg_sp.object_id
  value                 = random_password.rg_sp.result
  end_date_relative     = "4380h" # 6 months
}

resource "azuread_service_principal" "rg_sp" {
  application_id = azuread_application.rg_sp.application_id
}

resource "azurerm_role_assignment" "rg_sp" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.rg_sp.id
}

# SP - Key Vault Reader (just for Azure Pipeline)

resource "azuread_application" "kv_reader_sp" {
  name = "${local.name}-kv-reader-sp"
}

resource "azuread_application_password" "kv_reader_sp_secret" {
  application_object_id = azuread_application.kv_reader_sp.object_id
  value                 = random_password.kv_reader_sp.result
  end_date_relative     = "4380h" # 6 months
}

resource "azuread_service_principal" "kv_reader_sp" {
  application_id = azuread_application.kv_reader_sp.application_id
}
