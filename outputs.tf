output "resource_group_name" {
  description = "Resource group that contains the lab."
  value       = azurerm_resource_group.main.name
}
output "bastion_name" {
  description = "Azure Bastion host used to reach the VMs."
  value       = azurerm_bastion_host.main.name
}
output "admin_username" {
  description = "Login username for all the lab VMs."
  value       = var.admin_username
}
output "vm_private_ips" {
  description = "Private IPs of the lab VMs."
  value = {
    windows = azurerm_network_interface.vm["windows"].private_ip_address
    ubuntu  = azurerm_network_interface.vm["ubuntu"].private_ip_address
    notkali    = azurerm_network_interface.vm["notkali"].private_ip_address
  }
}
output "connection_hint" {
  description = "How to connect."
  value = join("", [
    "Portal > Resource Group > select VM > Connect > Bastion. ",
    "Windows/NotKali/Ubuntu all use RDP (xrdp installed on Linux)."
  ])
}