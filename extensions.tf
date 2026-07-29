resource "azurerm_virtual_machine_extension" "windows_base" {
  name               = "install-base"
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
        file("${path.module}/scripts/windows-base-setup.ps1"),
        "UTF-16LE"
      )
    ])
  })

  timeouts {
    create = "60m" // 60 minute timeout - overrides the default timeout and gives plenty of headroom 
  }
}

resource "azurerm_virtual_machine_extension" "windows_detection" {
  name                       = "install-detection"
  virtual_machine_id         = azurerm_windows_virtual_machine.windows.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true
  tags                       = var.tags
  protected_settings = jsonencode({
    commandToExecute = join("", [
      "powershell -ExecutionPolicy Unrestricted -EncodedCommand ",
      textencodebase64(
        file("${path.module}/scripts/windows-detection-setup.ps1"),
        "UTF-16LE"
      )
    ])
  })

  provision_after_extensions = ["install-base"] // this forces the detection extension to wait for the base to finsih 

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