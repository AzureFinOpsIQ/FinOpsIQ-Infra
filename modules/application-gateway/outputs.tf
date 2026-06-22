output "id" {
  description = "Application Gateway resource ID."
  value       = azurerm_application_gateway.this.id
}

output "name" {
  description = "Application Gateway name."
  value       = azurerm_application_gateway.this.name
}

output "public_ip_id" {
  description = "Application Gateway public IP resource ID."
  value       = azurerm_public_ip.this.id
}

output "public_ip_address" {
  description = "Application Gateway public IP address."
  value       = azurerm_public_ip.this.ip_address
}

output "public_ip_fqdn" {
  description = "Application Gateway public IP FQDN."
  value       = azurerm_public_ip.this.fqdn
}

output "waf_policy_id" {
  description = "Application Gateway WAF policy resource ID."
  value       = azurerm_web_application_firewall_policy.this.id
}

output "waf_policy_name" {
  description = "Application Gateway WAF policy name."
  value       = azurerm_web_application_firewall_policy.this.name
}
