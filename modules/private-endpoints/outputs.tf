output "private_endpoint_ids" {
  description = "Private endpoint IDs keyed by logical service name."
  value       = { for key, endpoint in azurerm_private_endpoint.this : key => endpoint.id }
}

output "private_endpoint_names" {
  description = "Private endpoint names keyed by logical service name."
  value       = { for key, endpoint in azurerm_private_endpoint.this : key => endpoint.name }
}
