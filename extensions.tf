resource "azurerm_virtual_machine_extension" "windows" {
  name               = "install-tooling" // all three VMs share this name... this is fine because extension names must be unique per VM, and not globally
  virtual_machine_id = azurerm_windows_virtual_machine.windows.id
  // implicit dependency that guarantees the VM exists before the extension runs
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true
  tags                       = var.tags

  protected_settings = jsonencode({
    commandToExecute = join("", [
      "powershell -ExecutionPolicy Unrestricted -EncodedCommand ",
      textencodebase64(
        file("${path.module}/scripts/win-setup.ps1"),
        "UTF-16LE"
      )
    ])
  })

  timeouts {
    create = "60m" // 60 minute timeout - overrides the default timeout and gives plenty of headroom - needed for Kali's install which may take approx 25 mins
  }
}

resource "azurerm_virtual_machine_extension" "ubuntu" {
  name                       = "install-tooling"
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

resource "azurerm_virtual_machine_extension" "kali" {
  name                       = "install-tooling"
  virtual_machine_id         = azurerm_linux_virtual_machine.kali.id
  publisher                  = "Microsoft.Azure.Extensions"
  type                       = "CustomScript"
  type_handler_version       = "2.1"
  auto_upgrade_minor_version = true
  tags                       = var.tags

  protected_settings = jsonencode({
    script = base64encode(
      templatefile("${path.module}/scripts/kali-setup.sh", {
        admin_username = var.admin_username
      })
    )
  })

  timeouts {
    create = "60m"
  }
}