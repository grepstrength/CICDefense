resource "azurerm_virtual_machine_extension" "windows" {
  name                       = "install-tooling"
  virtual_machine_id         = azurerm_windows_virtual_machine.windows.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true
  tags                       = var.tags
  // settings = plaintext
  settings = jsonencode({
    fileUris = [
      "https://raw.githubusercontent.com/grepstrength/CICDefense/main/scripts/win-setup.ps1"
    ]
  })
  // protected_settings = encrypted by Azure
  protected_settings = jsonencode({
    commandToExecute = "powershell -ExecutionPolicy Unrestricted -Command \"net user nottavictim '${var.user_password}' /add; net localgroup Users nottavictim /add; ./win-setup.ps1\""
  })

  timeouts {
    create = "60m"
  }
}

resource "azurerm_virtual_machine_extension" "ubuntu" {
  name                       = "install-tooling" // all the Linux VMs share this name... this is fine because extension names must be unique per VM, and not globally
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
        user_password  = var.user_password
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
        user_password  = var.user_password
      })
    )
  })

  timeouts {
    create = "90m" // 90 minute timeout because notkali installs heavy... 15 offensive tools are installed inline w/o backgrounding
  }
}

resource "azurerm_virtual_machine_extension" "kali" {
  count                      = var.enable_kali ? 1 : 0 //same count gate as the Kali VM and NIC
  name                       = "install-tooling"
  virtual_machine_id         = azurerm_linux_virtual_machine.kali[0].id
  publisher                  = "Microsoft.Azure.Extensions"
  type                       = "CustomScript"
  type_handler_version       = "2.1"
  auto_upgrade_minor_version = true
  tags                       = var.tags

  protected_settings = jsonencode({
    script = base64encode(
      file("${path.module}/scripts/kali-setup.sh") // no variables to inject
    )
  })
  timeouts {
    create = "30m" // this can afford to be shorter than the others because this extension does next to nothing
  }

}