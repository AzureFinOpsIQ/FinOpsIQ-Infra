output "private_dns_zone_id" {
  description = "Private DNS zone resource ID."
  value       = azurerm_private_dns_zone.this.id
}

output "private_dns_zone_name" {
  description = "Private DNS zone name."
  value       = azurerm_private_dns_zone.this.name
}
