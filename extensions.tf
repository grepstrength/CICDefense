resource "azurerm_virtual_machine_extension" "windows" {
  name                       = "install-tooling"
  virtual_machine_id         = azurerm_windows_virtual_machine.windows.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true
  tags                       = var.tags

  settings = jsonencode({
    fileUris = [
      "https://raw.githubusercontent.com/grepstrength/CICDefense/main/scripts/win-setup.ps1"
    ]
    commandToExecute = "powershell -ExecutionPolicy Unrestricted -File win-setup.ps1"
  })

  timeouts {
    create = "60m"
  }
}

resource "azurerm_virtual_machine_extension" "ubuntu" {
  name                       = "install-tooling" // the two Linux VMs share this name... this is fine because extension names must be unique per VM, and not globally
  virtual_machine_id         = azurerm_linux_virtual_machine.ubuntu.id
  publisher                  = "Microsoft.Azure.Extensions"
  type                       = "CustomScript"
  type_handler_version       = "2.1"
  auto_upgrade_minor_version = true
  tags                       = var.tags

  protected_settings = jsonencode({
    script = base64encode(
      templatefile("${path.module}/scripts/ubuntu-setup.sh", {
        admin_username = var.admin_username
      })
    )
  })

  timeouts {
    create = "60m"
  }
}

resource "azurerm_virtual_machine_extension" "notkali" {
  name                       = "install-tooling"
  virtual_machine_id         = azurerm_linux_virtual_machine.notkali.id
  publisher                  = "Microsoft.Azure.Extensions"
  type                       = "CustomScript"
  type_handler_version       = "2.1"
  auto_upgrade_minor_version = true
  tags                       = var.tags

  protected_settings = jsonencode({
    script = base64encode(
      templatefile("${path.module}/scripts/notkali-setup.sh", {
        admin_username = var.admin_username
      })
    )
  })

  timeouts {
    create = "90m" // 90 minute timeout because notkali installs heavy... 15 offensive tools are installed inline w/o backgrounding
  }
}