output "vm_id" {
  description = "Management VM resource ID."
  value       = azurerm_linux_virtual_machine.this.id
}

output "vm_name" {
  description = "Management VM name."
  value       = azurerm_linux_virtual_machine.this.name
}

output "vm_private_ip" {
  description = "Management VM private IP address."
  value       = azurerm_network_interface.this.private_ip_address
}

output "vm_principal_id" {
  description = "System-assigned managed identity principal ID for the management VM."
  value       = azurerm_linux_virtual_machine.this.identity[0].principal_id
}

output "network_security_group_id" {
  description = "Management subnet NSG ID."
  value       = azurerm_network_security_group.this.id
}
