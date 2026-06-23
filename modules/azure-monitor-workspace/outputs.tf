output "id" {
  description = "Azure Monitor Workspace resource ID."
  value       = azurerm_monitor_workspace.this.id
}

output "name" {
  description = "Azure Monitor Workspace name."
  value       = azurerm_monitor_workspace.this.name
}
