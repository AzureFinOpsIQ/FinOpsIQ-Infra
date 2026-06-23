output "id" {
  description = "Azure Managed Grafana resource ID."
  value       = azurerm_dashboard_grafana.this.id
}

output "name" {
  description = "Azure Managed Grafana name."
  value       = azurerm_dashboard_grafana.this.name
}

output "endpoint" {
  description = "Azure Managed Grafana endpoint."
  value       = azurerm_dashboard_grafana.this.endpoint
}

output "principal_id" {
  description = "Azure Managed Grafana system-assigned managed identity principal ID."
  value       = azurerm_dashboard_grafana.this.identity[0].principal_id
}
