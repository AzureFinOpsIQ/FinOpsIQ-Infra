output "bastion_id" {
  description = "Azure Bastion resource ID."
  value       = azurerm_bastion_host.this.id
}

output "bastion_name" {
  description = "Azure Bastion host name."
  value       = azurerm_bastion_host.this.name
}

output "bastion_host" {
  description = "Azure Bastion DNS name."
  value       = azurerm_bastion_host.this.dns_name
}
