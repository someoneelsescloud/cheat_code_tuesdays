########### Locals ###########
locals {

  assetname   = "mgmt"
  environment = "dev"
  location    = "westus"

  rg_name  = format("%s-%s-%s-rg-1", local.assetname, local.environment, local.location)
  res_name = format("%s-%s", local.assetname, local.environment)
  sa_name  = format("%sstorageacc%s", local.assetname, random_integer.number.result)
  kv_name  = format("%s-%s-kv-%s", local.assetname, local.environment, random_integer.number.result)

}

resource "random_integer" "number" {
  min = 50
  max = 99
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

########### Resource Group  ###########
resource "azurerm_resource_group" "resourcegroup_1" {
  name     = local.rg_name
  location = local.location
}

resource "azurerm_virtual_network" "virtualnetwork_1" {
  name                = "${local.res_name}-vnet-1"
  location            = azurerm_resource_group.resourcegroup_1.location
  resource_group_name = azurerm_resource_group.resourcegroup_1.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = local.environment
  }

}

resource "azurerm_subnet" "subnet_1" {
  name                 = "${local.res_name}-subnet-1"
  virtual_network_name = azurerm_virtual_network.virtualnetwork_1.name
  resource_group_name  = azurerm_resource_group.resourcegroup_1.name
  address_prefixes     = ["10.0.1.0/24"]

  depends_on = [
    azurerm_virtual_network.virtualnetwork_1
  ]
}

########### KeyVault ###########
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "keyvault_1" {
  name                        = local.kv_name
  location                    = azurerm_resource_group.resourcegroup_1.location
  resource_group_name         = azurerm_resource_group.resourcegroup_1.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  purge_protection_enabled    = false

  enabled_for_deployment          = true
  enabled_for_template_deployment = true

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get",
    ]

    secret_permissions = [
      "Get",
      "Backup",
      "Delete",
      "List",
      "Purge",
      "Recover",
      "Restore",
      "Set"
    ]

    storage_permissions = [
      "Get",
    ]
  }

  tags = {
    environment = local.environment
  }

}

resource "azurerm_key_vault_secret" "localadmin" {
  name         = "localadmin"
  value        = random_password.password.result
  key_vault_id = azurerm_key_vault.keyvault_1.id

  depends_on = [
    azurerm_key_vault.keyvault_1
  ]
}

########### Storage Account #1 ###########

resource "azurerm_storage_account" "storage_1" {
  name                     = local.sa_name
  resource_group_name      = azurerm_resource_group.resourcegroup_1.name
  location                 = azurerm_resource_group.resourcegroup_1.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = local.environment
  }

}
