resource "azurerm_network_interface" "vm" {
  for_each = toset(["windows", "notkali", "ubuntu"])

  name                = "${var.project_name}-${each.key}-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.workload.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "windows" {
  name                = "${var.project_name}-win"
  computer_name       = "win-runner"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  tags                = var.tags

  network_interface_ids = [
    azurerm_network_interface.vm["windows"].id
  ]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
    disk_size_gb         = 128
  }
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "windowsserver2022"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }
}

resource "azurerm_linux_virtual_machine" "ubuntu" {
  name                            = "${var.project_name}-ubuntu"
  computer_name                   = "ubuntu-runner"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  size                            = var.vm_size
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  tags                            = var.tags
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.vm["ubuntu"].id
  ]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
    disk_size_gb         = 64
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}

resource "azurerm_linux_virtual_machine" "notkali" {
  name                            = "${var.project_name}-notkali"
  computer_name                   = "notkali-dast"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  size                            = var.vm_size
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  tags                            = var.tags
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.vm["notkali"].id
  ]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
    disk_size_gb         = 64
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}

resource "azurerm_marketplace_agreement" "kali" {
  count = var.enable_kali ? 1 : 0 // conditional expression that depends on enable_kali being true in (variables.tf) to create the VM, if false, the value is 0 and nothing gets built

  publisher = "kali-linux"
  offer     = "kali-linux"
  plan      = "kali"
}

resource "azurerm_network_interface" "kali" {
  count = var.enable_kali ? 1 : 0

  name                = "${var.project_name}-kali-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.workload.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "kali" {
  count = var.enable_kali ? 1 : 0 // Again, only enabled when enable_kali = true

  name                            = "${var.project_name}-kali"
  computer_name                   = "kali"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  size                            = var.vm_size
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  tags                            = var.tags
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.kali[0].id
  ]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
    disk_size_gb         = 64
  }
  source_image_reference {
    publisher = "kali-linux"
    offer     = "kali-linux"
    sku       = "kali"
    version   = "latest"
  }
  plan {
    name      = "kali"
    product   = "kali-linux"
    publisher = "kali-linux"
  }
  depends_on = [azurerm_marketplace_agreement.kali]
}