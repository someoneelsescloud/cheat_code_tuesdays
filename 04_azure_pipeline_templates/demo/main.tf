########### Locals ###########
locals {
  rg_name    = "${var.assetname}-${var.environment}-${var.location}-rg-1"
  res_name   = "${var.assetname}-${var.environment}"
  sa_name    = "${var.assetname}storageacc001"
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

########### Management 1 ###########
data "azurerm_resource_group" "resourcegroup_1" {
  name     = local.rg_name
}

########### Networking 1 ###########

resource "azurerm_virtual_network" "virtualnetwork_1" {
  name                = "${local.res_name}-vnet-1"
  location            = data.azurerm_resource_group.resourcegroup_1.location
  resource_group_name = data.azurerm_resource_group.resourcegroup_1.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = var.environment
  }

}

resource "azurerm_subnet" "subnet_1" {
  name                 = "${local.res_name}-subnet-1"
  virtual_network_name = azurerm_virtual_network.virtualnetwork_1.name
  resource_group_name  = data.azurerm_resource_group.resourcegroup_1.name
  address_prefixes     = ["10.0.1.0/24"]

  depends_on = [
    azurerm_virtual_network.virtualnetwork_1
  ]
}

########### Virtual Machine 1 ###########
resource "azurerm_network_interface" "virtualmachine_1" {
  name                = "${local.res_name}-nic-1"
  location            = data.azurerm_resource_group.resourcegroup_1.location
  resource_group_name = data.azurerm_resource_group.resourcegroup_1.name

  ip_configuration {
    name                          = "${local.res_name}-1"
    subnet_id                     = azurerm_subnet.subnet_1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.virtualmachine_1.id
  }

  tags = {
    environment = var.environment
  }

  depends_on = [
    azurerm_subnet.subnet_1
  ]

}

resource "azurerm_public_ip" "virtualmachine_1" {
  name                    = "${local.res_name}-public-vm-nic-1"
  location                = data.azurerm_resource_group.resourcegroup_1.location
  resource_group_name     = data.azurerm_resource_group.resourcegroup_1.name
  allocation_method       = "Dynamic"
  idle_timeout_in_minutes = 10
}

resource "azurerm_windows_virtual_machine" "virtualmachine_1" {
  name                  = "${local.res_name}-vm-1"
  location              = data.azurerm_resource_group.resourcegroup_1.location
  resource_group_name   = data.azurerm_resource_group.resourcegroup_1.name
  network_interface_ids = [azurerm_network_interface.virtualmachine_1.id]
  size                  = "Standard_DS1_v2"
  admin_username        = "localadmin"
  admin_password        = random_password.password.result

  provision_vm_agent = true
  timezone           = "AUS Eastern Standard Time"

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  tags = {
    environment = var.environment
  }

  depends_on = [
    azurerm_subnet.subnet_1
  ]


}
