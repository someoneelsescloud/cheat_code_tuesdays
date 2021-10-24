########### Resource Group #1 ###########
resource "azurerm_resource_group" "legacy_rg_1" {
  name     = "legacy-dev-westus-rg-1"
  location = "westus"
}

########### Virtual Machine #1 ###########
resource "azurerm_public_ip" "legacy_public_1" {
  name                    = "legacyvm01-ip"
  location                = azurerm_resource_group.legacy_rg_1.location
  resource_group_name     = azurerm_resource_group.legacy_rg_1.name
  allocation_method       = "Dynamic"
  idle_timeout_in_minutes = 4
}

resource "azurerm_network_interface" "legacy_nic_1" {
  name                = "legacyvm01845"
  location            = azurerm_resource_group.legacy_rg_1.location
  resource_group_name = azurerm_resource_group.legacy_rg_1.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet_1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.legacy_public_1.id
  }

}

resource "azurerm_windows_virtual_machine" "legacy_vm_1" {
  name                  = "legacyvm01"
  location              = azurerm_resource_group.legacy_rg_1.location
  resource_group_name   = azurerm_resource_group.legacy_rg_1.name
  network_interface_ids = [azurerm_network_interface.legacy_nic_1.id]
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
    environment = "dev"
  }

}