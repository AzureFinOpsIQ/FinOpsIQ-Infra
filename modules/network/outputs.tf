output "vnet_id" {
  description = "Virtual network resource ID."
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "Virtual network name."
  value       = azurerm_virtual_network.this.name
}

output "subnet_ids" {
  description = "Subnet IDs keyed by logical name."
  value       = { for key, subnet in azurerm_subnet.this : key => subnet.id }
}

output "subnet_names" {
  description = "Subnet names keyed by logical name."
  value       = { for key, subnet in azurerm_subnet.this : key => subnet.name }
}

output "network_security_group_ids" {
  description = "Network Security Group IDs keyed by logical name."
  value       = { for key, nsg in azurerm_network_security_group.this : key => nsg.id }
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs keyed by logical name."
  value       = { for key, nat in azurerm_nat_gateway.this : key => nat.id }
}

output "private_dns_zone_ids" {
  description = "Private DNS Zone IDs keyed by logical name."
  value       = { for key, zone in azurerm_private_dns_zone.this : key => zone.id }
}
